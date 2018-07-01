#!/usr/bin/env bash
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
eval "$(ssh-agent -s)"; ssh-add -K ~/.ssh/key.1ambda.github.io_rsa
STORAGE="zookeeper" ${CURRENT_DIR}/provision.sh
