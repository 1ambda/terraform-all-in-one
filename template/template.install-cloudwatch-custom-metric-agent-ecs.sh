#!/bin/bash
cd /root
${installer} install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA curl zip unzip
curl -L https://github.com/alexanderbh/ExtendedCloudWatchScripts/archive/${agent_version}.tar.gz -O
tar -zxvf ${agent_version}.tar.gz
mv ExtendedCloudWatchScripts-${agent_version} ExtendedCloudWatchScripts
mv ExtendedCloudWatchScripts /home/${user}/
chown ${user}:${user} /home/${user}/ExtendedCloudWatchScripts

# should use `root` since we block metadata access from normal users
echo "*/1 * * * * /home/${user}/ExtendedCloudWatchScripts/mon-put-instance-data.pl --lv-space-util --lv-space-avail --auto-scaling --mem-util --mem-avail --disk-path=/ --disk-space-util --disk-space-avail --memory-units=megabytes --disk-space-units=gigabytes --from-cron" >> /var/spool/cron/root
