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
}
