#!/usr/bin/env bash

eval "$(ssh-agent -s)"; ssh-add -K ~/.ssh/key.1ambda.github.io_rsa
ssh -N -L 2181:10.0.11.118:2181 ec2-user@13.125.9.147

