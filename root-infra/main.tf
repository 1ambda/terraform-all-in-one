module "module-vpc" {
  source = "module-vpc"

  region = "${var.region}"
  company = "${var.company}"
  project = "${var.project}"
  environment = "${var.environment}"

  availability_zones = "${var.availability_zones}"
  kops_cluster_name = "${local.kops_cluster_name}"
}


