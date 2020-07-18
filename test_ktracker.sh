#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
echo "*****Testing Ktracker*****\n"
test_if_no_resource_type_passed() {
  echo "Executing: test_if_no_resource_type_passed"
  sh ktracker.sh > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code == 0 ]]; then
    echo "${RED} Failure: test_if_no_resource_type_passed ==> Expected: Error when no resource type provided but did not fail; exiting"
    echo "${NC}"
    exit 1
  fi
  echo "${GREEN} Passed: test_if_no_resource_type_passed ==> ktracker fails when resource type is not provided to track"
  echo "${NC}"
}
utility_execute_ktracker_with_correct_resource_type() {
  resource_type=$1
  calling_function_name=$2
  echo "Executing: $calling_function_name" 
  sh ktracker.sh $resource_type > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code != 0 ]]; then
    echo "${RED} Failure: $calling_function_name ==> Expected: ktracker should not fail if ${resource_type} is passed as resource type with or without options; exiting"
    echo "${NC}"
    exit 1
  fi
  echo "${GREEN} Passed: $calling_function_name ==> ktracker passes when ${resource_type} is passed as resource type"
  echo "${NC}"
}
utility_execute_ktracker_with_wrong_resource_type() {
  resource_type=$1
  calling_function_name=$2
  echo "Executing: $calling_function_name" 
  sh ktracker.sh $resource_type > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code == 0 ]]; then
    echo "${RED} Failure: $calling_function_name ==> Expected: ktracker should fail if ${resource_type} is passed as resource type with or without options; exiting"
    echo "${NC}"
    exit 1
  fi
  echo "${GREEN} Passed: $calling_function_name ==> ktracker fails when ${resource_type} is passed as resource type"
  echo "${NC}"
}
utility_execute_ktracker_with_correct_options() {
  resource_type=$1
  calling_function_name=$2
  option=$3
  option_value=$4
  echo "Executing: $calling_function_name" 
  sh ktracker.sh $resource_type $option $option_value > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code != 0 ]]; then
    echo "${RED} Failure: $calling_function_name ==> Expected: ktracker should not fail if ${resource_type} is passed as resource type with $option $option_value as option; exiting"
    echo "${NC}"
    exit 1
  fi
  echo "${GREEN} Passed: $calling_function_name ==> ktracker passes when ${resource_type} is passed as resource type with $option $option_value as option"
  echo "${NC}"
}
utility_execute_ktracker_with_wrong_options() {
  resource_type=$1
  calling_function_name=$2
  option=$3
  option_value=$4
  echo "Executing: $calling_function_name" 
  sh ktracker.sh $resource_type $option $option_value > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code == 0 ]]; then
    echo "${RED} Failure: $calling_function_name ==> Expected: ktracker should fail if ${resource_type} is passed as resource type with $option $option_value as option; exiting"
    echo "${NC}"
    exit 1
  fi
  echo "${GREEN} Passed: $calling_function_name ==> ktracker fails when ${resource_type} is passed as resource type with $option $option_value as option"
  echo "${NC}"
}
test_if_pods_passed_as_resource_type() {
  utility_execute_ktracker_with_correct_resource_type po test_if_po_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type pods test_if_pods_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type pod test_if_pod_passed_as_resource_type
}
test_if_deployments_passed_as_resource_type() {
  utility_execute_ktracker_with_correct_resource_type deployments test_if_deployments_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type deployment test_if_deployment_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type deploy test_if_deploy_passed_as_resource_type
}
test_if_services_passed_as_resource_type() {
  utility_execute_ktracker_with_correct_resource_type services test_if_services_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type service test_if_service_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type svc test_if_svc_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type svcs test_if_svcs_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type deploys test_if_deploys_passed_as_resource_type
  utility_execute_ktracker_with_correct_resource_type pos test_if_pos_passed_as_resource_type
}
test_if_invalid_resource_is_passed_as_resource_type() {
  utility_execute_ktracker_with_wrong_resource_type suraj test_if_suraj_passed_as_resource_type
  utility_execute_ktracker_with_wrong_resource_type pandey test_if_pandey_passed_as_resource_type
  utility_execute_ktracker_with_wrong_resource_type bavlin test_if_bavlin_passed_as_resource_type
  utility_execute_ktracker_with_wrong_resource_type ps test_if_ps_passed_as_resource_type
  utility_execute_ktracker_with_wrong_resource_type deplys test_if_deplys_passed_as_resource_type
  utility_execute_ktracker_with_wrong_resource_type srvcs test_if_srvcs_passed_as_resource_type
}
test_if_valid_options_are_passed_to_ktracker() {
  utility_execute_ktracker_with_correct_options po test_if_-nm_passed_as_option -nm suraj 
  utility_execute_ktracker_with_correct_options po test_if_-lb_passed_as_option -lb suraj 
  utility_execute_ktracker_with_correct_options po test_if_-lm_passed_as_option -lm 2 
  utility_execute_ktracker_with_correct_options po test_if_-dn_passed_as_option -dn 
  utility_execute_ktracker_with_correct_options po test_if_-ex_passed_as_option -ex 
  utility_execute_ktracker_with_correct_options po test_if_-em_passed_as_option -em me.suraj.pandey@nielsen.com 
  utility_execute_ktracker_with_correct_options po test_if_-ns_passed_as_option -ns my_name_space 
}
test_if_invalid_options_are_passed_to_ktracker() {
  utility_execute_ktracker_with_wrong_options po test_if_-mn_passed_as_option -mn suraj 
  utility_execute_ktracker_with_wrong_options po test_if_-bl_passed_as_option -bl suraj 
  utility_execute_ktracker_with_wrong_options po test_if_-ll_passed_as_option -ll 2 
  utility_execute_ktracker_with_wrong_options po test_if_-dn_passed_as_option -dn 1
  utility_execute_ktracker_with_wrong_options po test_if_-ex_passed_as_option -ex 1 
  utility_execute_ktracker_with_wrong_options po test_if_-me_passed_as_option -me me.suraj.pandey@nielsen.com 
  utility_execute_ktracker_with_wrong_options po test_if_-sn_passed_as_option -sn suraj_name_space
}
test_if_no_resource_type_passed
test_if_pods_passed_as_resource_type
test_if_deployments_passed_as_resource_type
test_if_services_passed_as_resource_type
test_if_invalid_resource_is_passed_as_resource_type
test_if_valid_options_are_passed_to_ktracker
test_if_invalid_options_are_passed_to_ktracker
