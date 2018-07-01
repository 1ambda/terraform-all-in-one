locals {
  security_group_name = "storage-baremetal.${lower(var.project)}.${lower(var.company)}.io"
}

resource "aws_security_group" "storage-baremetal" {
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

output "storage-baremetal_security_group_id" {
  value = "${aws_security_group.storage-baremetal.id}"
}

resource "aws_security_group_rule" "storage-baremetal_allow_ssh_from_bastion" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  source_security_group_id = "${var.bastion_security_group_id}"

  security_group_id = "${aws_security_group.storage-baremetal.id}"
}

resource "aws_security_group_rule" "storage_allow_to_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.storage-baremetal.id}"
}

resource "aws_security_group_rule" "storage_allow_all_from_self" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  source_security_group_id = "${aws_security_group.storage-baremetal.id}"

  security_group_id = "${aws_security_group.storage-baremetal.id}"
}

# Zookeeper

resource "aws_security_group_rule" "storage-baremetal_allow_zookeeper_from_bastion" {
  type            = "ingress"
  from_port       = "${var.zookeeper_port}"
  to_port         = "${var.zookeeper_port}"
  protocol        = "tcp"
  source_security_group_id = "${var.bastion_security_group_id}"

  security_group_id = "${aws_security_group.storage-baremetal.id}"
}
