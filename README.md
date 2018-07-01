# terraform-all-in-one

Provide fine-grained Kubernetes + Infrastructure Terraform files for AWS in 30 mins 🚀

- [Prerequisite](#prerequisite)
- [Usage](#usage)
- [Features](#features)
- [Credits](#credits)

<br/>

## Prerequisite

- [ansible](https://github.com/ansible/ansible)
- [jq](https://github.com/stedolan/jq)
- [terraform](https://github.com/hashicorp/terraform)
- [kops](https://github.com/kubernetes/kops)
- [awscli](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)

```bash
$ brew install ansible jq terraform kops watch
$ pip install awscli

$ git clone git@github.com:1ambda/terraform-all-in-one.git
$ cd terraform-all-one

# Remove .gitigonre to index generated files
rm .gitignore
```

## Usage

### 1. Export AWS Key Environment variables

The key should have `AdministratorAccess` permission.

```bash
$ export AWS_ACCESS_KEY_ID={VALUE} AWS_SECRET_ACCESS_KEY={VALUE}
```

### 2. Generate SSH Key Pair

```bash
# Modify values for `COMPANY`,`PROJECT`, and `EMAIL`
$ COMPANY=github PROJECT=1ambda EMAIL=1ambda@github.com ./create-ssh-key.sh
```

### 3. Modify Terraform Variables to Customize

- [variable.customize.tf](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/variable.customize.tf)
- [variable.resource.tf](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/variable.resource.tf)

[company](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/variable.customize.tf#L8) and [project](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/variable.customize.tf#L13) variable should match with values used for the generated ssh key.

### 4. Applying Terraform Modules

- [x] **root-infra**: Create VPC, Bastion, ECS, Stroages and build kops scripts
    ```bash
    cd root-infra;

    # build infra using terraform
    terraform init
    terraform apply -var 'rds_username={USERNAME}' -var 'rds_password={PASSWORD}'

    # provision non-managed stroages using ansible
    ../script-provision/generated.provision-zookeeper.sh
    ```

- [x] **root-kubernetes**: [Build Kubernetes Cluster](https://github.com/1ambda/terraform-all-in-one/tree/master/root-kubernetes#1-creating-cluster) and [install add-ons](https://github.com/1ambda/terraform-all-in-one/tree/master/root-kubernetes#2-deploying-add-ons)
    ```bash
    cd root-kubernetes;

    # generate kops files
    $(cat generated.kops-env.sh);
    ./generated.kops-create.sh;

    # build kubernetes cluster
    terraform init
    terraform apply

    # wait for few minitues until Kube API ELB is ready (`api-kops-*`)
    # then validate the created cluster
    kops export kubecfg --name=$NAME
    ./generated.correct-kubectl-context.sh

    # wait for 3-5 mins until kubernetes cluster is ready
    kops validate cluster
    kubectl get pods
    ```

## Features

- [VPC](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-vpc/vpc.tf)
- [Basiton Host](https://github.com/1ambda/terraform-all-in-one/tree/master/root-infra/module-bastion)
    * [Install Storage Clients (e.g mysql, redis, ..) using user-data](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-bastion/bastion-lc.tf#L1-L18)
    * [Configurable SSH Whitelist](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-bastion/security-group.bastion.tf#L28-L42)
    * [SSH Connection](https://github.com/1ambda/terraform-all-in-one/blob/master/script-ssh/generated.ssh-bastion.sh), [Proxy Utilities](https://github.com/1ambda/terraform-all-in-one/blob/master/script-ssh/generated.ssh-proxy-zookeeper-01.sh)
- [ECS](https://github.com/1ambda/terraform-all-in-one/tree/master/root-infra/module-ecs)
    * [ASG Scaling Policies](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-ecs/ecs-asg-scaling-policy.tf)
    * [Cloudwatch Log Groups for ECS AWSLOGS](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-ecs/ecs-awslogs.tf)
    * [Cloudwatch Custom Metrics + Alerts for ECS: Logical Volume](https://github.com/1ambda/terraform-all-in-one/blob/master/template/template.install-cloudwatch-custom-metric-agent-ecs.sh)
    * [Customized Container Volume Size (--storage-opt dm.basesize)](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-ecs/ecs-lc.tf#L75-L80)
    * [Report Inactive ECS Host Machine to Slack via Lambda + ECS Event](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-ecs/ecs-monitoring-event-instance-availability.tf)
    * [Dynamic Cloudwatch Alarm Registration for ASG Event](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-messaging/sns-lambda-asg-event.tf)
- [Managed Storages: RDS (MariaDB), Elasticsearch, Elasticache (Redis)](https://github.com/1ambda/terraform-all-in-one/tree/master/root-infra/module-storage-managed)
    * [Cloudwatch Default Metrics + Alerts](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-managed/storage-ec-cloudwatch-alarm.tf)
    * [Cloudwatch Log Groups for RDS: Audit, Slow Index, Error, General](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-managed/storage-rds.tf#L167-L172)
    * [Cloudwatch Log Groups for ES: Slow Query, Slow Index](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-managed/storage-es.tf#L68-L78)
    * [Configurable Clustering](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/variable.resource.tf#L13-L27)
    * [RDS option group for utf8mb4](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-managed/storage-rds.tf#L49-L92) :see_no_evil:
- [Barematal Storages: Zookeeper](https://github.com/1ambda/terraform-all-in-one/tree/master/root-infra/module-storage-managed)
    * [Ansible Provisioning](https://github.com/1ambda/terraform-all-in-one/tree/master/script-provision)
    * [Cloudwatch Log Groups for ZK AWSLOGS](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-baremetal/storage-zookeeper-awslogs.tf)
    * [Cloudwatch Custom Metrics](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-baremetal/storage-zookeeper.tf#L49-L73) + [Alerts for EC2: Memory, Disk Space](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-baremetal/storage-zookeeper-cloudwatch-alarm.tf)
    * [ELB-backed Health Check (Cloudwatch Alarm ](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-storage-baremetal/storage-zookeeper.tf#L123-L153)
- [Kubernetes Cluster (Single Master)](https://github.com/1ambda/terraform-all-in-one/tree/master/root-kubernetes)
    * [Terraform Intergrated Kubernetes Cluster Creation using kops](https://github.com/1ambda/terraform-all-in-one/tree/master/root-infra/module-kops)
    * [Cloudwatch Log Groups for Kube AWSLOGS](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-kops/kops-awslogs.tf)
    * [Dynamic Cloudwatch Alarm Registration for ASG Event](https://github.com/1ambda/terraform-all-in-one/blob/master/root-kubernetes/kubernetes-monitoring-cloudwatch-alarm.tf#L133-L146)
    * [Cloudwatch Custom Metrics](https://github.com/1ambda/terraform-all-in-one/blob/master/root-infra/module-kops/template.kops-manifest.yaml#L80-L94) + [Alerts for EC2: Memory, Disk Space](https://github.com/1ambda/terraform-all-in-one/blob/master/root-kubernetes/kubernetes-monitoring-cloudwatch-alarm.tf)
    * [add-on: Nginx Ingerss Chart with AWS ACM](https://github.com/1ambda/terraform-all-in-one/tree/master/root-kubernetes#21-acm--nginx-ingress)
    * [add-on: Kubernetes Dashboard](https://github.com/1ambda/terraform-all-in-one/tree/master/root-kubernetes#21-acm--nginx-ingress)
    * [add-on: Elasticsearch, Kibana, Fluentd](https://github.com/1ambda/terraform-all-in-one/tree/master/root-kubernetes#23-ekf--es-curator)

## Credits

- [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [terraform-sns-slack](https://github.com/builtinnya/aws-sns-slack-terraform)

