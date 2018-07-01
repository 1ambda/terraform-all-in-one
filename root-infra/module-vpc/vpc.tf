module "vpc" {
  # https://github.com/terraform-aws-modules/terraform-aws-vpc
  source = "terraform-aws-modules/vpc/aws"

  name = "VPC-${var.company}-${var.project}"
  cidr = "10.0.0.0/16"

  azs             = "${var.availability_zones}"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]

  # one NAT gateway per AZ
  enable_nat_gateway = true
  single_nat_gateway  = false
  one_nat_gateway_per_az = true

  enable_vpn_gateway = true

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    # required for kops-generated kubernetes
    "kubernetes.io/cluster/${var.kops_cluster_name}" = "shared"
  }
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.vpc.public_subnets}"
}

output "private_subnet_ids" {
  value = "${module.vpc.private_subnets}"
}

output "vpc_cidr" {
  value = "${module.vpc.vpc_cidr_block}"
}

output "private_subnets_cidr_blocks" {
  value = "${module.vpc.private_subnets_cidr_blocks}"
}

output "public_subnets_cidr_blocks" {
  value = "${module.vpc.public_subnets_cidr_blocks}"
}
