#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TAG="[$(basename -- "$0")]"

function print_usage {
    echo "usage: $0 [-ek]"
    echo "  -e, --ecs     display ecs instance IPs"
    echo "  -k, --kube    display kube instance IPs"
    echo "  -h  --help    display help"
    exit 1
}

for arg in "$@"; do
  shift
  case "$arg" in
    "--help")   set -- "$@" "-h" ;;
    "--ecs")    set -- "$@" "-e" ;;
    "--kube")   set -- "$@" "-k" ;;
    "--"*)      print_usage ${arg}; exit 2;;
    *)          set -- "$@" "$arg"
  esac
done

# Default behavior
OPT_ECS="false"; OPT_KUBE="false"

# Parse short options
OPTIND=1
while getopts "ekh" opt
do
  case "$opt" in
    "h") print_usage; exit 0 ;;
    "e") OPT_ECS="true" ;;
    "k") OPT_KUBE="true" ;;
    "?") print_usage >&2; exit 1 ;;
  esac
done
shift $(expr $OPTIND - 1) # remove options from positional parameters

if [ -f "${CURRENT_DIR}/inventory.storage-baremetal" ]; then
  echo -e "${TAG} Displaying Baremetal Storages"
  cat ${CURRENT_DIR}/inventory.storage-baremetal
  echo -e ""
fi

if [ -f "${CURRENT_DIR}/inventory.storage-managed" ]; then
  echo -e "${TAG} Displaying Managed Storages"
  cat ${CURRENT_DIR}/inventory.storage-managed
  echo -e ""
fi

if [ "${OPT_KUBE}" == "true" ]; then
  echo -e "${TAG} Displaying Kubernetes Nodes"
  kubectl config use-context kops.${project}.${company}.k8s.local
  echo -e "	(kubernetes)"
  kubectl get nodes
  echo -e ""
fi

if [ "${OPT_ECS}" == "true" ]; then
  echo -e "${TAG} Displaying ECS Instances"
  region="ap-northeast-2"
  tag="ecs.1ambda.github.io"
  echo -e "	(ecs cluster)"
  instance_ips=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${tag}" --query Reservations[].Instances[].PrivateIpAddress --output text --region ${region})
  for instance_ip in ${instance_ips}; do
    echo ${instance_ip}
  done
  echo -e ""
fi

echo -e "${TAG} Connecting to bastion..."
eval "$(ssh-agent -s)"; ssh-add -K ~/.ssh/key.1ambda.github.io_rsa
ssh -A ec2-user@52.79.211.95

