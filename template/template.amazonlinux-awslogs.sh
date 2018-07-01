#!/bin/bash

# Install awslogs and the jq JSON parser
yum update -y
yum install -y awslogs jq

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/${storage_log_path}]
file = /${storage_log_path}
log_group_name = /${awslogs_stream_prefix}/${storage_log_path}
log_stream_name = $${instance_id}

[/var/log/messages]
file = /var/log/messages
log_group_name = /${awslogs_stream_prefix}/var/log/messages
log_stream_name = $${instance_id}
datetime_format = %b %d %H:%M:%S
EOF

# replace region in `awscli.conf`
sed -i -e "s/region = us-east-1/region = ${region}/g" /etc/awslogs/awscli.conf

service awslogs start
chkconfig awslogs on

