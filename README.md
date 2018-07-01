# terraform-all-in-one

Provide fine-grained Kubernetes + Infrastructure Terraform files for AWS :)

## Usage

```bash
COMPANY=GITHUB PROJECT=1ambda EMAIL=1ambda@github.com ./create-ssh-key.sh
```

- [x] `root-infra`: Create VPC, Bastion, ECS, Stroages and build kops scripts
    ```bash
    cd root-infra

    # build infra using terraform
    terraform apply -var 'rds_username={USERNAME}' -var 'rds_password={PASSWORD}'

    # provision non-managed stroages using ansible
    ../script-provision/generated.provision-zookeeper.sh
    ```
- [x] `root-kubernetes`: Build kubernetes cluster and install add-ons
    ```bash
    cd root-kubernetes

    # generate kops files
    $(cat generated.kops-env.sh);
    ./generated.kops-create.sh;

    # build kubernetes cluster
    terraform apply
    ```

## Features

- VPC
- Basiton Host
    * Install storage clients (e.g mysql, redis, ..) using user-data
    * Configurable whitelist
    * SSH Connection, Proxy Utilities
- ECS
    * ASG Scaling Policies
    * Cloudwatch Log Groups for ECS related logs
    * Cloudwatch Custom Metrics + Alerts for ECS: Logical Volume
    * Customized Container Volume Size
    * Report Inactive ECS Host Machine to Slack via Lambda + ECS Event
    * Dynamic Cloudwatch Alarm Registration for ASG
- Managed Storages: RDS, Elasticsearch, Elasticache (Redis)
    * Cloudwatch Default Metrics + Alerts
    * Cloudwatch Log Groups for RDS: Audit, Slow Index, Error, General
    * Cloudwatch Log Groups for ES: Slow Query, Slow Index
    * Configurable Clustering
    * RDS option group for utf8mb4 :)
- Barematal Storages: Zookeeper
    * Ansible Provisioning
    * Cloudwatch Log Groups for ZK logs
    * Cloudwatch Custom Metrics + Alerts for EC2: Memory, Disk Space
    * ELB-backed health check
- Kubernetes Cluster
    * Terraform Intergrated Kubernetes Cluster by kops

## Credits

- [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [terraform-sns-slack](https://github.com/builtinnya/aws-sns-slack-terraform)

