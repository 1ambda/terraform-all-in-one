resource "aws_security_group" "bastion" {
  name = "bastion.${lower(var.project)}.${lower(var.company)}.io"

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "bastion.${lower(var.project)}.${lower(var.company)}.io"
  }

  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "bastion_allow_all_to_all" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]

  security_group_id = "${aws_security_group.bastion.id}"
}

locals {
  ssh_ingress = "${var.whitelist_enabled ? join(",", var.whitelist_targets) : "0.0.0.0/0"}"
}

resource "aws_security_group_rule" "bastion_allow_ssh_from_all" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = [
    "${split(",", local.ssh_ingress)}"
  ]

  security_group_id = "${aws_security_group.bastion.id}"
}

output "bastion_security_group_id" {
  value = "${aws_security_group.bastion.id}"
}

