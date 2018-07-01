#!/usr/bin/env bash

eval "$(ssh-agent -s)"; ssh-add -K ~/.ssh/key.1ambda.github.io_rsa
ssh -N -L 2181:10.0.12.17:2181 ec2-user@52.79.211.95

