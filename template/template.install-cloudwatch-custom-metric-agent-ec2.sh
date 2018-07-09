#!/bin/bash
cd /root

${installer} update -y

# https://forums.aws.amazon.com/thread.jspa?threadID=149117
${installer} install -y perl-core
${installer} install -y perl-Sys-Syslog
${installer} install -y perl-CGI
${installer} install -y perl-Switch perl-DateTime perl-LWP-Protocol-https perl-Digest-SHA.x86_64 curl zip unzip

curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-${agent_version}.zip -O
unzip CloudWatchMonitoringScripts-${agent_version}.zip
chown ${user}:${user} ./aws-scripts-mon
mv aws-scripts-mon /home/${user}/
echo "*/1 * * * * /home/${user}/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-avail --disk-path=/ --disk-space-util --disk-space-avail --memory-units=megabytes --disk-space-units=gigabytes --from-cron" >> /var/spool/cron/${user}
chown ${user}:${user} /var/spool/cron/${user}
