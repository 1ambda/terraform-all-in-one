variable "region" {}

variable "company" {}

variable "project" {}

variable "environment" {}

variable "vpc_id" {}

variable "private_subnet_ids" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

variable "bastion_security_group_id" {}

variable "on_testing" {}

variable "iam_policy_ec2_cloudwatch_arn" {}

variable "aws_key_pair_name" {}

variable "slack_webhook_url_alert" {}

variable "slack_webhook_channel_alert" {}

variable "sns_topic_cloudwatch_alarm_arn" {}

variable "sns_topic_arn_asg_event" {}