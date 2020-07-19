#!/bin/bash
resource_json_output=$1
resource_type=$2
cur_idx_resource=$3
resource_name=$4
event=$5

#separate the conditions and the result
IFS_BACKUP=$IFS
IFS=';'
read -a events_and_conditions <<< "$event"
IFS=$IFS_BACKUP
events=${events_and_conditions[0]}
conditions=${events_and_conditions[1]}
if [[ $events = "" && $conditions = "" ]]; then
  echo "Events and conditions empty, doin.. nothing"
  exit 0
fi
echo ${event_parsed[0]},${event_parsed[1]}
