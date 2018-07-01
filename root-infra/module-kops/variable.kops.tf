variable "region" {}
variable "company" {}
variable "project" {}
variable "environment" {}
variable "on_testing" {}

variable "vpc_id" {}
variable "vpc_cidr" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "private_subnets_cidr_blocks" {
  type = "list"
}

variable "public_subnets_cidr_blocks" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

variable "whitelist_targets" {
  type = "list"
}
variable "whitelist_enabled" {}

variable "bastion_public_ip" {}
variable "bastion_private_ip" {}

variable "ssh_public_key_path" {}
variable "kops_cluster_name" {}

variable "kube_master_instance_count" {}
variable "kube_master_instance_type" {}
variable "kube_master_root_volume_size" {}
variable "kube_worker_instance_count" {}
variable "kube_worker_instance_type" {}
variable "kube_worker_root_volume_size" {}

variable "kops_ami" {}
variable "kube_version" {}

variable "external_acm_use" {}
variable "domain_name" {}
variable "local_acm_validation_method" {}
