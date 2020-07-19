#!/bin/bash

#Defining constants for types of k8s resources
POD=1
SVC=2
DEPLOY=3

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
resource_type_id=${options[10]}
event=${options[11]}

track() {
  local max_attempt=5
  local timeout=2
  local attempt=0
  local increment=1
  local cur_namespace="default"
  local timeout_increment=1
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
      echo "Tracking all $num_k8s_resources $resource_type"
      track_num=$num_k8s_resources
    fi
    cur_idx_resource=0
    while [[ $cur_idx_resource -lt $track_num ]]
    do
      resource_name=$(echo $resource_json_output | jq '.items['${cur_idx_resource}'].metadata.name' | tr -d "\"")
      IFS=','
      if [[ $resource_type_id = 1 ]]; then
        pods_track_output=$(bash pods.sh "$resource_json_output" "$resource_type" "$cur_idx_resource" "$resource_name" "$event")
        read -a resource_track_output <<< "$pods_track_output"
      elif [[ $resource_type_id = 2 ]]; then
        pods_track_output=$(bash pods.sh $resource_json_output $resource_type $cur_idx_resource $resource_name)
        read -a resource_track_output <<< "$pods_track_output"
      elif [[ $resource_type_id = 3 ]]; then
        pods_track_output=$(bash pods.sh $resource_json_output $resource_type $cur_idx_resource $resource_name)
        read -a resource_track_output <<< "$pods_track_output"
      fi
      echo "$resource_type $resource_name is in state => ${resource_track_output[0]}"
      IFS=$IFS_BACKUP
      cur_idx_resource=$(( cur_idx_resource + 1 ))
    done
    sleep $timeout
    attempt=$(( attempt + increment ))
    timeout=$(( timeout * timeout_increment )) 
  done
}
track
