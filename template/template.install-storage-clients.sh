#!/bin/bash
cd /root
${installer} install -y mysql wget gcc
wget http://download.redis.io/redis-stable.tar.gz && tar xvzf redis-stable.tar.gz && cd redis-stable && make
cp /root/redis-stable/src/redis-cli /home/${user}/
chown ${user}:${user} /home/${user}/redis-cli

