#!/bin/bash
IFS_BACKUP=$IFS
IFS=','
output=$(sh validate_options.sh "$@")
exit_code=$?
read -a options <<<"$output" 
if [[ $exit_code != 0 ]]; then 
  echo "$output"
  exit 1;
fi
IFS=$IFS_BACKUP
resource_type=${options[0]}
name=${options[1]}
namespace=${options[2]}
label=${options[3]}
limit=${options[4]}
is_daemon=${options[5]}
email=${options[6]}
is_linear=${options[7]}
is_exponential=${options[8]}
track_num=${options[9]}

track() {
  local max_attempt=5
  local timeout=2
  local attempt=0
  local increment=1
  local cur_namespace="default"
  local timeout_increment=2
  if [[ $is_daemon != "" ]]; then
    increment=0
  fi
  if [[ $is_exponential != "" ]]; then
    timeout_increment=1
  fi
  if [[ $namespace != "" ]]; then
    cur_namespace=$namespace
  fi
  if [[ $label != "" ]]; then
    label_option="-l $label"
  fi
  echo "Tracking $resource_type in $cur_namespace namespace"
  while [[ $attempt < $max_attempt ]];
  do
    resource_json_output=$(kubectl get $resource_type $label_option -o json --sort-by=.metadata.creationTimestamp -n ${cur_namespace})
    num_k8s_resources=$(echo "$resource_json_output" | jq '.items | length')
    echo "There is/are $num_k8s_resources $resource_type based on the options provided in $cur_namespace namespace"
    if [[ $track_num != "" && $num_k8s_resources -ge $track_num ]]; then
      echo "Tracking $track_num $resource_type out of $num_k8s_resources $resource_type" 
    elif [[ $num_k8s_resources = "" || $num_k8s_resources = 0 ]]; then
      echo "Looks like there are 0 $resource_type to track in $cur_namespace namespace based on the options provided"
    else
      echo "Tracking all $track_num $resource_type"
      track_num=$num_k8s_resources
    fi
    cur_idx_resource=0
    while [[ $cur_idx_resource -lt $track_num ]]
    do
      resource_name=$(echo $resource_json_output | jq '.items['${cur_idx_resource}'].metadata.name' | tr -d "\"")
      echo "Current resource found is $resource_name"
      cur_idx_resource=$(( cur_idx_resource + 1 ))
    done
    sleep $timeout
    attempt=$(( attempt + increment ))
    timeout=$(( timeout * timeout_increment )) 
  done
}
track
