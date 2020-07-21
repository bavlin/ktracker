#!/bin/bash
resource_json_output=$1
resource_type=$2
cur_idx_resource=$3
resource_name=$4
event=$5

parse_first_key_value_pair_from_string() {
  input_string=$1
  key_value_pair=$(echo $input_string | sed -e "s/&&/&/g" | cut -d '&' -f1)
  input_string=$(echo $input_string | sed "s/.*=[0-9 ]*[& ]*//g")
  echo "$input_string"
}

parse_conditions() {
  condition_string=$1
  IFS_BACKUP=$IFS
  IFS='.'
  read -a condition_key <<< "$condition_string"
  IFS=$IFS_BACKUP
  if [[ ${condition_key[0]} != "event" ]]; then
    echo "Condition string not correct, exiting.."
    exit 1
  fi
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
  echo $conditions
  #echo $key_value_pair
done
