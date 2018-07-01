#!/bin/bash

# https://github.com/aws/amazon-ecs-init/issues/119#issuecomment-337402555
# rotate the docker daemon log when it reaches 100MB and keep at most 5 log files
cat <<EOF > /etc/logrotate.d/docker
/var/log/docker {
    rotate 5
    copytruncate
    missingok
    notifempty
    compress
    maxsize 100M
    dateext
    dateformat -%Y%m%d-%s
    create 0644 root root
}
EOF
