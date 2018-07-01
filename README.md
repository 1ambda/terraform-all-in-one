# terraform-all-in-one

Provide (semi) Production-ready Kubernetes + Infrastructure on AWS

## Requirement

```bash
COMPANY=GITHUB PROJECT=1ambda EMAIL=1ambda@github.com ./create-ssh-key.sh
```

## Features

- VPC
- Basiton Host
    * Install storage clients (e.g mysql, redis, ..) using user-data
    * Configurable whitelist
    * SSH Connection, Proxy Utilities
- ECS
    * ASG Policies
    * Cloudwatch Log Groups for ECS related logs
    * Cloudwatch Custom Metrics + Alerts for ECS: Logical Volume
    * Customized Container Volume Size
    * Report Inactive ECS Host Machine to Slack via Lambda + ECS Event
    * Dynamic Cloudwatch Alarm Registration for ASG
- Managed Storages: RDS, Elasticsearch, Elasticache (Redis)
    * Configurable Clustering
    * RDS option group for utf8mb4 :)
- Barematal Storages: Zookeeper
    * Ansible Provisioning
    * Cloudwatch Log Groups for ZK logs
    * Cloudwatch Custom Metrics + Alerts for EC2: Memory, Disk Space
    * ELB-backed health check
- Kubernetes Cluster



