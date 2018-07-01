#!/usr/bin/env bash

set -e # stop if fails

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

USAGE="Usage: INSTANCE_COUNT={NUMBER} STORAGE={TYPE} BASTION_USER={NAME} BASTION_HOST={NAME} STORAGE_USER={NAME} STORAGE_POSTFIX={VALUE} SSH_PRIVATE_KEY={PATH} $0"

if [ -z "$STORAGE" ] ; then
    echo ${USAGE}
    exit 1
fi

TAG="[$(basename -- "$0")]"
INVENTORY_FILE="inventory.${STORAGE}.ansible"
PLAYBOOK_FILE="generated.playbook-${STORAGE}.yml"
SSHCFG_FILE="ssh.${STORAGE}.cfg"

echo "${TAG} ${STORAGE} inventory:"
echo ""
cat ${CURRENT_DIR}/${INVENTORY_FILE}

echo ""
echo "${TAG} ssh.cfg for ansible:"
cat ${CURRENT_DIR}/${SSHCFG_FILE}

echo ""
echo "${TAG} generated ansible playbook:"
cat ${CURRENT_DIR}/${PLAYBOOK_FILE}

echo ""
read -p "${TAG} Do you want to play? (y/n): " yn

if [ "$yn" != "y" ]; then
  echo -e "${TAG} Deployment is canceled\n"
  exit 0
fi

echo ""
echo "${TAG} ansible-playbook -i ${INVENTORY_FILE} -s ${PLAYBOOK_FILE}"
ANSIBLE_ENABLE_TASK_DEBUGGER=True ANSIBLE_SSH_ARGS="-F ${CURRENT_DIR}/${SSHCFG_FILE}" ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --limit all -i ${CURRENT_DIR}/${INVENTORY_FILE} -s ${CURRENT_DIR}/${PLAYBOOK_FILE}
