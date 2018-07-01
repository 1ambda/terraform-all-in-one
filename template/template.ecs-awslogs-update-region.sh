#!/bin/bash
sed -i -e "s/region = us-east-1/region = ${region}/g" /etc/awslogs/awscli.conf
