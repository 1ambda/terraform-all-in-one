#!/usr/bin/env bash

eval "$(ssh-agent -s)"; ssh-add -K ${ssh_private_key_path}
ssh -N -L ${storage_port}:${storage_host}:${storage_port} ${bastion_user}@${bastion_host}
