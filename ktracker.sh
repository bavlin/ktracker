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
  local max_attempt=1
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
  echo "Tracking $resource_type inside $cur_namespace namespace"
  while [[ $attempt < $max_attempt ]];
  do
    resource_json_output=$(kubectl get $resource_type $label_option -o json --sort-by=.metadata.creationTimestamp -n ${cur_namespace})
    num_k8s_resources=$(echo "$resource_json_output" | jq '.items | length')
    echo "There is/are $num_k8s_resources $resource_type based on the options provided in $cur_namespace namespace"
    if [[ $track_num != "" && $num_k8s_resources -ge $track_num ]]; then
      echo "Tracking $track_num $resource_type out of $num_k8s_resources $resource_type" 
    elif [[ $num_k8s_resources = "" || $num_k8s_resources = 0 ]]; then
      echo "Since there are 0 $resource_type in $cur_namespace, doing nothing" 
    else
      echo "Tracking all $track_num $resource_type"
      track_num=$num_k8s_resources
    fi
    cur_idx_resource=0
    while [[ $cur_idx_resource -lt $track_num ]]
    do
      resource_name=$(echo $resource_json_output | jq '.items['${cur_idx_resource}'].metadata.name' | tr -d "\"")
      resource_status=$(echo $resource_json_output | jq '.items['${cur_idx_resource}'].status.containerStatuses[].state | keys | .[0]' | tr -d "\"")
      if [[ $resource_status = "failed" ]]; then
        exit_code=$(echo $resource_json_output | jq '.terminated.exitCode')
        echo "$resource_type found => $resource_name has finished with status failed and the exit code is $exit_code"
      elif [[ $resource_status = "running" ]]; then
        echo "$resource_type found => $resource_name is still in running status"
      elif [[ $resource_status = "pending" ]]; then
        echo "$resource_type found => $resource_name is still in pending status"
      elif [[ $resource_status = "succeeded" ]]; then
        exit_code=$(echo $resource_json_output | jq '.terminated.exitCode')
        echo "$resource_type found => $resource_name has succeeded with exit code $exit_code"
      elif [[ $resource_status = "unknown" ]]; then
        echo "$resource_type found => $resource_name is in Unknown status"
      fi
      cur_idx_resource=$(( cur_idx_resource + 1 ))
    done
    sleep $timeout
    attempt=$(( attempt + increment ))
    timeout=$(( timeout * timeout_increment )) 
  done
}
track
