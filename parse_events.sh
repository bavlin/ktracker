#!/bin/bash
resource_json_output=$1
resource_type=$2
cur_idx_resource=$3
resource_name=$4
event=$5
last_condition_operator="&&"

parse_first_key_value_pair_from_string() {
  input_string=$1
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
  condition=$(echo $condition_string | cut -d '=' -f1)
  condition_value=$(echo $condition_string | cut -d '=' -f2)
  IFS_BACKUP=$IFS
  IFS='.'
  read -a condition_key <<< "$condition"
  IFS=$IFS_BACKUP
  if [[ ${condition_key[0]} != "event" ]]; then
    echo "Condition string not correct, must start with event, exiting.."
    exit 1
  fi

  if [[ ${condition_key[1]} != "condition" ]]; then
    echo "Condition string not correct, must start with condition, exiting.."
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
IFS=';'
read -a conditions_and_results <<< "$event"
IFS=$IFS_BACKUP
conditions=${conditions_and_results[0]}
results=${conditions_and_results[1]}
if [[ $conditions = "" && $results = "" ]]; then
  echo "Both conditions and results empty, doin.. nothing"
  exit 0
fi
num_of_and_conditions=$(echo $conditions | grep -o "&&" | wc -l)
num_of_or_conditions=$(echo $conditions | grep -o "||" | wc -l)
total_conditions=$(( num_of_and_conditions + num_of_or_conditions + 1 ))
for i in {1..$total_conditions}
do
  conditions=$(parse_first_key_value_pair_from_string "$conditions")
  parse_conditions "$key_value_pair"
  echo $conditions
  #echo $key_value_pair
done
