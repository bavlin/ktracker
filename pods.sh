#!/bin/bash
resource_json_output=$1
resource_type=$2
cur_idx_resource=$3
resource_name=$4
event=$5
resource_status=$(echo $resource_json_output | jq '.items['${cur_idx_resource}'].status.containerStatuses[].state | keys | .[0]' | tr -d "\"")
event_output=$(bash parse_events.sh "$resource_json_output" "$resource_type" "$cur_idx_resource" "$resource_name" "$event")
exit_code="0"
if [[ $resource_status = "failed" ]]; then
  exit_code=$(echo $resource_json_output | jq '.terminated.exitCode')
  #echo "$resource_type found => $resource_name has finished with status failed and the exit code is $exit_code"
elif [[ $resource_status = "running" ]]; then
  #echo "$resource_type found => $resource_name is still in running status"
  exit_code="0" #Doin..nothing
elif [[ $resource_status = "pending" ]]; then
  #echo "$resource_type found => $resource_name is still in pending status"
  exit_code="0" #Doin..nothing
elif [[ $resource_status = "succeeded" ]]; then
  exit_code=$(echo $resource_json_output | jq '.terminated.exitCode')
  #echo "$resource_type found => $resource_name has succeeded with exit code $exit_code"
elif [[ $resource_status = "unknown" ]]; then
  #echo "$resource_type found => $resource_name is in Unknown status"
  exit_code="0" #Doin..nothing
fi
echo "$event_output~$resource_status~$exit_code"
