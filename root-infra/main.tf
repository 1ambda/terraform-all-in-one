module "module-vpc" {
  source = "module-vpc"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"

  availability_zones = "${var.availability_zones}"
  kops_cluster_name = "${local.kops_cluster_name}"
}

module "module-messaging" {
  source = "module-messaging"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"

  slack_alert_enable = "${local.slack_alert_enable}"
  slack_webhook_url = "${local.slack_webhook_url_alert}"
  slack_webhook_channel = "${local.slack_webhook_channel_alert}"
}

module "module-iam" {
  source = "module-iam"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"
}

module "module-bastion" {
  source = "module-bastion"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"
  on_testing = "${var.on_testing}"

  ssh_public_key_path = "${local.ssh_public_key_path}"
  ssh_private_key_path = "${local.ssh_private_key_path}"

  vpc_id = "${module.module-vpc.vpc_id}"
  public_subnet_ids = "${module.module-vpc.public_subnet_ids}"

  multiple_bastions = false
  iam_policy_ec2_cloudwatch_arn = "${module.module-iam.iam_policy_ec2_cloudwatch_arn}"

  sns_topic_cloudwatch_alarm_arn = "${module.module-messaging.sns_topic_arn_cloudwatch_alarm}"

  whitelist_enabled = "${local.whitelist_enabled}"
  whitelist_targets = ["${local.whitelist_targets}"]

  kops_cluster_name = "${local.kops_cluster_name}"
}

module "module-ecs" {
  source = "module-ecs"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"
  on_testing = "${var.on_testing}"

  sns_topic_cloudwatch_alarm_arn = "${module.module-messaging.sns_topic_arn_cloudwatch_alarm}"
  sns_topic_arn_asg_event = "${module.module-messaging.sns_topic_arn_asg_event}"

  # network
  vpc_id = "${module.module-vpc.vpc_id}"
  private_subnet_ids = "${module.module-vpc.private_subnet_ids}"
  availability_zones = "${var.availability_zones}"
  bastion_security_group_id = "${module.module-bastion.bastion_security_group_id}"

  aws_key_pair_name = "${module.module-bastion.aws_key_pair_name}"
  iam_policy_ec2_cloudwatch_arn = "${module.module-iam.iam_policy_ec2_cloudwatch_arn}"

  asg_cooldown = 180
  asg_min_size = 1
  asg_max_size = 3
  asg_desired_capacity = 1
  asg_instance_type = "${local.ecs_instance_type}"
  ecs_host_root_disk_size = "${local.ecs_host_root_disk_size}"
  ecs_container_total_disk_size = "${local.ecs_container_total_disk_size}"
  ecs_container_per_disk_size = "${local.ecs_container_per_disk_size}"
  ecs_task_cleanup_duration = "120h"
  ecs_image_minimum_cleanup_age = "72h"

  slack_webhook_url_alert = "${local.slack_webhook_url_alert}"
  slack_webhook_channel_alert = "${local.slack_webhook_channel_alert}"
}

module "module-storage-baremetal" {
  source = "module-storage-baremetal"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"
  on_testing = "${var.on_testing}"
  sns_topic_cloudwatch_alarm_arn = "${module.module-messaging.sns_topic_arn_cloudwatch_alarm}"

  # network
  vpc_id = "${module.module-vpc.vpc_id}"
  private_subnet_ids = "${module.module-vpc.private_subnet_ids}"
  availability_zones = "${var.availability_zones}"
  bastion_security_group_id = "${module.module-bastion.bastion_security_group_id}"
  bastion_public_ip = "${module.module-bastion.bastion_public_ip}"

  aws_key_pair_name = "${module.module-bastion.aws_key_pair_name}"
  ssh_private_key_path = "${local.ssh_private_key_path}"
  iam_policy_ec2_cloudwatch_arn = "${module.module-iam.iam_policy_ec2_cloudwatch_arn}"

  zookeeper_clustering = "${local.zookeeper_clustering}"
  zookeeper_instance_type = "${local.zookeeper_instance_type}"
}

variable "rds_username" {
  default = "will be override"
}
variable "rds_password" {
  default = "will be override"
}

module "module-storage-managed" {
  source = "module-storage-managed"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"
  on_testing = "${var.on_testing}"
  sns_topic_cloudwatch_alarm_arn = "${module.module-messaging.sns_topic_arn_cloudwatch_alarm}"

  # network
  vpc_id = "${module.module-vpc.vpc_id}"
  private_subnet_ids = "${module.module-vpc.private_subnet_ids}"
  availability_zones = "${var.availability_zones}"
  bastion_security_group_id = "${module.module-bastion.bastion_security_group_id}"

  # elasticache (redis)
  ec_redis_version = "3.2.10"
  ec_clustering = "${local.ec_clustering}"
  ec_instance_type = "${local.ec_instance_type}"
  ec_snapshot_window = "15:00-16:00" # UTC
  ec_maintenance_window = "Sun:16:30-Sun:17:30" # UTC

  # elasticsearch
  es_clustering = "${local.es_clustering}"
  es_node_instance_type = "${local.es_node_instance_type}"
  es_node_disk_size = "${local.es_node_disk_size}"
  es_master_instance_type = "${local.es_master_instance_type}"
  es_version = "6.0"
  es_snapshot_window_start_hour_utc = 22

  # RDS
  rds_username = "${var.rds_username}"
  rds_password = "${var.rds_password}"
  rds_clustering = "${local.rds_clustering}"
  rds_instance_type = "${local.rds_instance_type}"
  rds_disk_size = "${local.rds_disk_size}"
  rds_backup_window = "15:00-15:30" # UTC
  rds_maintenance_window = "Sun:16:00-Sun:19:00" # UTC
}

module "module-kops" {
  source = "module-kops"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"
  on_testing = "${var.on_testing}"

  # network
  vpc_id = "${module.module-vpc.vpc_id}"
  vpc_cidr = "${module.module-vpc.vpc_cidr}"
  private_subnet_ids = "${module.module-vpc.private_subnet_ids}"
  public_subnet_ids = "${module.module-vpc.public_subnet_ids}"
  private_subnets_cidr_blocks = "${module.module-vpc.private_subnets_cidr_blocks}"
  public_subnets_cidr_blocks = "${module.module-vpc.public_subnets_cidr_blocks}"
  availability_zones = "${var.availability_zones}"

  # kops
  ssh_public_key_path = "${local.ssh_public_key_path}"
  kops_cluster_name = "${local.kops_cluster_name}"
  kube_master_instance_count = "${local.kube_master_instance_count}"
  kube_master_instance_type = "${local.kube_master_instance_type}"
  kube_master_root_volume_size = "${local.kube_master_root_volume_size}"
  kube_worker_instance_count = "${local.kube_worker_instance_count}"
  kube_worker_instance_type = "${local.kube_worker_instance_type}"
  kube_worker_root_volume_size = "${local.kube_worker_root_volume_size}"

  kops_ami = "${local.kops_ami}"
  kube_version = "${local.kube_version}"

  # whitelist
  whitelist_enabled = "${local.whitelist_enabled}"
  whitelist_targets = ["${local.whitelist_targets}"]
  bastion_private_ip = "${module.module-bastion.bastion_private_ip}"
  bastion_public_ip = "${module.module-bastion.bastion_public_ip}"

  # domain, ssl
  domain_name = "${local.domain_name}"
  external_acm_use = "${local.external_acm_use}"
  local_acm_validation_method = "${local.local_acm_validation_method}"
}
