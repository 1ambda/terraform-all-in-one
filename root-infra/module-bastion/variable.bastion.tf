variable "region" {}

variable "company" {}

variable "project" {}

variable "environment" {}

variable "on_testing" {}

variable "ssh_private_key_path" {}

variable "vpc_id" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "whitelist_targets" {
  type = "list"
}

variable "whitelist_enabled" {}

variable "iam_policy_ec2_cloudwatch_arn" {}

variable "kops_cluster_name" {}