#!/bin/bash
resource_json_output=$1
resource_type=$2
cur_idx_resource=$3
resource_name=$4
event=$5
last_condition_operator="&&"

parse_key_value_pair_from_string() {
  #match_group_idx=$(( match_group_idx - 1 ))
  #key_value_pair=$(echo $input_string | sed -e "s/&&/&/g" | cut -d ' ' -f1)
  key_value_pair=$(echo $conditions | sed -e "s/ *\&\& */\&/g" | awk -F '&' '{print $1}')
  #key_value_pair=$(echo $input_string | grep -oE -m 1 ".+&&")
  if [[ $key_value_pair = "" ]]; then
    #key_value_pair=$(echo $input_string | grep -oE -m 1 ".+||")
    key_value_pair=$(echo $conditions | sed -e "s/ *\&\& */\&/g" | awk -F '|' 'print {$1}')
    if [[ $key_value_pair = "" ]]; then
      key_value_pair="$input_string"
    fi
  fi
  conditions=$(echo $conditions | sed -E "s/ \&\& /\&\&/1" | sed -E "s/.*=.*[^ ]&&//g")
  
  #pattern="(.* && )"
  #if [[ $input_string =~ $pattern ]]; then
  #  key_value_pair="${BASH_REMATCH[$match_group_idx]}"
  #else
  #  pattern=".* ||"
  #  if [[ "$input_string" =~ "$pattern" ]]; then
  #    key_value_pair=${BASH_REMATCH[$match_group_idx]}
  #    key_value_pair=$(echo $key_value_pair | sed -e "s/ ||//g")
  #  fi
  #fi
  #key_value_pair=$(echo $input_string | sed )
  #key=$(echo $key_value_pair | cut -d '=' -f1)
  #value=$(echo $key_value_pair | cut -d '=' -f2)
  ##input_string=$(echo $input_string | sed "s/.*=[0-9 ]*[& ]*//g")
  #echo "$input_string"
}

parse_first_key_value_pair_from_string() {
  local input_string=$1
  key_value_pair=$(echo $input_string | sed -e "s/&&/&/g" | cut -d '&' -f1)
  input_string=$(echo $input_string | sed "s/.*=[0-9 ]*[& ]*//g")
  echo "$input_string"
}

parse_condition_if_type_is_definition() {
  condtion=$1
  condition_value=$2
  condition=$(echo $condition | cut -d'.' -f3-)
  IFS_BACKUP=$IFS
  IFS='.'
  read -a condition <<< "$condition"
  IFS=$IFS_BACKUP
  last_condition=${condition[-1]}
  for each_condition in ${conditions[@]}; do
   if [[ $each_condition != "*" ]]; then
     jq_command=$(echo 'tostream | select(length == 2 and .[1] == "$condition_value" ) as [$p,$v] | $p | index("$each_condition")' | sed -e "s/\$condition_value/$condition_value/g" | sed -e "s/\$each_condition/$each_condition/g")
     idx=$(echo $resource_json_output | jq '$jq_command') 
     if [[ $idx == null ]]; then
       echo "Event condition $each_condition did not match anything defined in the $resource_type resource json"
       exit 1
     fi
   else
     jq_command=$(echo 'tostream | select(length == 2 and .[1] == "$condition_value" ) as [$p,$v] | $p | index("$last_condition")' | sed -e "s/\$condition_value/$condition_value/g" | sed -e "s/\$last_condition/$last_condition/g")
     idx=$(echo $resource_json_output | jq '$jq_command') 
     if [[ $idx == null ]]; then
       echo "Event condition $last_condition did not match anything defined in the $resource_type resource json"
       exit 1
     fi
   fi 
  done
}

parse_conditions() {
  condition_string=$1
  echo $condition_string
  condition=$(echo $condition_string | cut -d '=' -f1)
  condition_value=$(echo $condition_string | cut -d '=' -f2)
  IFS_BACKUP=$IFS
  IFS='.'
  read -a condition_key <<< "$condition"
  IFS=$IFS_BACKUP
  if [[ ${condition_key[0]} != "event" ]]; then
    echo "Condition string not correct, --given to me=> $condition, but it must start with event, exiting.."
    exit 1
  fi

  if [[ ${condition_key[1]} != "condition" ]]; then
    echo "Condition string not correct, --given to me=> $condition must start with condition, exiting.."
  fi
  
  if [[ ${condition_key[2]} = "definition" ]]; then
    parse_condition_if_type_is_defintion "$condition" "$condition_value"
  fi 
  #.. | .suraj? | length
  #tostream | select(.[0][-1]=="a") as [$p,$v] | $p
  #tostream | select(length == 2 and .[1]=="b") as [$p,$v] | $p
  #walk( if type == "object" then with_entries( select(.key == "a") ) else . end ) | .[0] | length 
}

#separate the conditions and the result
IFS_BACKUP=$IFS
IFS=';' #Event and Results are seperated by ;
read -a conditions_and_results <<< "$event"
IFS=$IFS_BACKUP
if [[ $conditions_and_results == null ]]; then
  echo "No events to process, doin.. nothing"
fi
conditions=${conditions_and_results[0]}
results=${conditions_and_results[1]}
if [[ $conditions = "" ]]; then
  echo "No conditions to track, doin.. nothing"
  exit 0
fi
if [[ $results == "" ]]; then
  echo "No result given to be executed based on the condition"
  exit 0
fi
num_of_and_conditions=$(echo $conditions | grep -o "&&" | wc -l)
num_of_or_conditions=$(echo $conditions | grep -o "||" | wc -l)
total_conditions=$(( num_of_and_conditions + num_of_or_conditions ))
total_return=""
for ((i=0;i<=$total_conditions;i++));
do
  parse_key_value_pair_from_string
  total_return="$key_value_pair#$total_return"
  #echo $key_value_pair  
  #parse_conditions "$key_value_pair"
  #echo $conditions
  #echo $key_value_pair
done
echo "$total_return"
