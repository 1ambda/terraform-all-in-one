locals {
  security_group_name = "storage-managed.${lower(var.project)}.${lower(var.company)}.io"
}

resource "aws_security_group" "storage-managed" {
  name = "${local.security_group_name}"
  description = "${local.security_group_name}"

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.security_group_name}"
  }

  vpc_id = "${var.vpc_id}"
}

output "storage-managed_security_group_id" {
  value = "${aws_security_group.storage-managed.id}"
}

resource "aws_security_group_rule" "storage-managed_allow_ssh_from_bastion" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  source_security_group_id = "${var.bastion_security_group_id}"

  security_group_id = "${aws_security_group.storage-managed.id}"
}

resource "aws_security_group_rule" "storage_allow_to_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.storage-managed.id}"
}

resource "aws_security_group_rule" "storage_allow_all_from_self" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  source_security_group_id = "${aws_security_group.storage-managed.id}"

  security_group_id = "${aws_security_group.storage-managed.id}"
}

# Elasticache (redis)

resource "aws_security_group_rule" "storage-managed_allow_ec_from_bastion" {
  type = "ingress"
  from_port = "${var.ec_port}"
  to_port = "${var.ec_port}"
  protocol = "tcp"
  source_security_group_id = "${var.bastion_security_group_id}"

  security_group_id = "${aws_security_group.storage-managed.id}"
}

# Elasticsearch

resource "aws_security_group_rule" "storage-managed_allow_es_from_bastion" {
  type = "ingress"
  from_port = "${var.es_http_port}"
  to_port = "${var.es_http_port}"
  protocol = "tcp"
  source_security_group_id = "${var.bastion_security_group_id}"

  security_group_id = "${aws_security_group.storage-managed.id}"
}

# RDS (mariadb)

resource "aws_security_group_rule" "storage-managed_allow_rds_from_bastion" {
  type = "ingress"
  from_port = "${var.rds_port}"
  to_port = "${var.rds_port}"
  protocol = "tcp"
  source_security_group_id = "${var.bastion_security_group_id}"

  security_group_id = "${aws_security_group.storage-managed.id}"
}
