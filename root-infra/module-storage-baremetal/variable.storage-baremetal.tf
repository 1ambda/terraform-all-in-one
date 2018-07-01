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

variable "aws_key_pair_name" {}

variable "ssh_private_key_path" {}

locals {
  configured_azs = {
    standalone = [
      "${var.availability_zones[0]}",
    ]
    clustering = [
      "${var.availability_zones}",
    ]
  }

  configured_subnets = {
    standalone = [
      "${element(coalescelist(var.private_subnet_ids, list("DUMMY")), 0)}",
    ]
    clustering = [
      "${var.private_subnet_ids}",
    ]
  }
}

variable "sns_topic_cloudwatch_alarm_arn" {}
