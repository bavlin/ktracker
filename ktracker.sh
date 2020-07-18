#!/bin/bash
num_args="$#"
if [[ "$num_args" -lt 1 ]]; then
  echo "Resource type required to track"
  echo "Usage: ktracker << pod/po/pods | deployments/deploy/deployment | service/services/svc >> [options]"
  echo "Use: ktracker --help | -h for help; exiting ..."
  exit 1
fi
resource_type=$1
case $resource_type in
  pod|po|pods|pos)
    echo "Tracking pods"
  ;;
  deployments|deploy|deployment|deploys)
    echo "Tracking deployments"
  ;;
  service|services|svc|svcs)
    echo "Tracking services"
  ;;
  *)
    echo "Unknown resource type $resource_type; Use: ktracker --help | -h for help;  exiting..."
    exit 1
esac
shift
while [[ "$#" -gt 0 ]]
do
  key="$1"
  case $key in
    -nm|--name)
    name="$2"
    shift 
    shift
    ;;
    -ns|--namespace)
    namespace="$2"
    shift 
    shift
    ;;
    -lb|--label)
    label="$2"
    shift
    shift
    ;;
    -lm|--limit)
    limit="$2"
    shift
    shift
    ;;
    -ln|--linear)
    is_linear=1
    shift
    ;;
    -ex|--exponential)
    is_exponential=1
    shift
    ;;
    -dn|--daemon)
    is_daemon=1
    shift
    ;;
    -em|--email)
    email="$2"
    shift
    shift
    ;;
    *)
    echo "Unknown argument $1; Use: ktracker --help | -h for help;  exiting..."
    exit 1
    ;;
  esac
done
echo "Arguments: name is $name, ns is $namespace, label is $label, limit is $limit, is_daemon is $is_daemon, email is $email"
if [[ $is_daemon == 1 && ! -z $limit ]]; then
  echo "ktracker can only be run either as a daemon forever or for a certain iterations using limit option"
  echo "Use: ktracker --help | -h for help; exiting ..."
  exit 1
fi
if [[ ! -z $is_exponential && ! -z $is_linear ]]; then
  echo "ktracker can only be run either with linear polling or exponential polling, not both"
  echo "Use: ktracker --help | -h for help; exiting ..."
  exit 1
fi

