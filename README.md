# terraform-all-in-one

## Requirement

```bash
COMPANY=GITHUB PROJECT=1ambda EMAIL=1ambda@github.com ./create-ssh-key.sh
```

## Features

- VPC
- Basiton Host
    * Install storage clients (e.g mysql, redis, ..) using user-data
    * Configurable whitelist
- ECS
    * ASG Policies
    * Cloudwatch Log Groups for ECS related logs
    * Cloudwatch Custom Metrics for ECS: Logical Volume
    * Customized Container Volume Size
    * Report Inactive ECS Host Machine to Slack via Lambda + ECS Event
    * Dynamic Cloudwatch Alarm Registration for ASG
- Kubernetes Cluster



