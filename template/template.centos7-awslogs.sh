#!/bin/bash

cd /root

# install awslogs and jq
yum update -y
yum install -y jq

# https://forums.aws.amazon.com/thread.jspa?threadID=165134
mkdir -p /var/lib/awslogs

instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
cat > ./awslogs.conf <<- EOF
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

curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/AgentDependencies.tar.gz -O
tar xvf AgentDependencies.tar.gz -C /tmp/
python ./awslogs-agent-setup.py --region ${region} --non-interactive --configfile ./awslogs.conf --dependency-path /tmp/AgentDependencies

