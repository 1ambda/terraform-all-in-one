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
