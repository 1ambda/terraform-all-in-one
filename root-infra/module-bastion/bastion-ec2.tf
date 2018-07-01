variable "multiple_bastions" {
  default = false
}

locals {
  instance_name = "bastion.${lower(var.project)}.${lower(var.company)}.io"
  ash_tf_resource_name = "ASG-${var.company}-${var.project}_bastion"
}

resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ec2_amazon_linux.id}" # ami-92df37ed

  lifecycle {
    ignore_changes = [
      "ami",
      "user_data",
    ]
  }

  instance_type = "t2.nano"
  subnet_id = "${element(var.public_subnet_ids, 0)}"

  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}",
  ]
  associate_public_ip_address = true

  key_name = "${aws_key_pair.this.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.bastion.name}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "25"
    delete_on_termination = "true"
  }

  user_data = "${data.template_cloudinit_config.bastion_user_data.rendered}"

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.instance_name}"
  }
}

output bastion_instance_name {
  value = "${local.instance_name}"
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "bastion_private_ip" {
  value = "${aws_instance.bastion.private_ip}"
}
