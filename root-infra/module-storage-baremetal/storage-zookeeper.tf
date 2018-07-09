variable "zookeeper_clustering" {}
variable "zookeeper_instance_type" {}
variable "zookeeper_port" {
  default = 2181
}
output "zookeeper_port" {
  value = "${var.zookeeper_port}"
}
output "zookeeper_dns_list" {
  value = "${aws_instance.zookeeper.*.private_dns}"
}
variable "zookeeper_user" {
  default = "ec2-user"
  # amazon linux ami
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  # ref:  https://aws.amazon.com/amazon-linux-ami/
  filter {
    name = "name"
    values = [
      "amzn-ami-*-x86_64-gp2",
    ]
  }
  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon"]
  }
}

data "template_file" "zookeeper_userdata_install_cloudwatch_custom_metric_agent" {
  template = "${file("${path.root}/../template/template.install-cloudwatch-custom-metric-agent-ec2.sh")}"

  vars {
    user = "ec2-user"
    installer = "yum"
    agent_version = "1.2.2"
  }
}

data "template_cloudinit_config" "zookeeper_user_data" {
  gzip = false
  base64_encode = true

  # install awslogs and setup
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.zookeeper_userdata_awslogs.rendered}"
  }

  # install agent for cloudwatch custom metric
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.zookeeper_userdata_install_cloudwatch_custom_metric_agent.rendered}"
  }

  # apply amazon linux patces
  part {
    content_type = "text/x-shellscript"
    content = <<EOF
#!/bin/bash
yum update -y

EOF
  }
}

resource "aws_instance" "zookeeper" {
  ami = "${data.aws_ami.amazon_linux.id}"
  # ami-3185744e
  lifecycle {
    ignore_changes = [
      "ami",
      "user_data",
    ]
  }

  depends_on = [
    "aws_cloudwatch_log_group.zookeeper_instance_message",
    "aws_cloudwatch_log_group.zookeeper_storage_log",
  ]

  count = "${var.zookeeper_clustering ? 3 : 1}"
  instance_type = "${var.on_testing ? "t2.micro" : var.zookeeper_instance_type}"

  subnet_id = "${element(var.private_subnet_ids, count.index%length(var.private_subnet_ids))}"
  vpc_security_group_ids = [
    "${aws_security_group.storage-baremetal.id}"]
  associate_public_ip_address = false

  key_name = "${var.aws_key_pair_name}"
  iam_instance_profile = "${aws_iam_instance_profile.storage_baremetal.name}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "120"
    # GB
    delete_on_termination = "true"
  }

  user_data = "${data.template_cloudinit_config.zookeeper_user_data.rendered}"

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "zookeeper-${format("%02d", count.index + 1)}.${lower(var.project)}.${lower(var.company)}.io"
  }
}

# ELB: ZK ELB is used only for monitoring backend instances.

resource "aws_elb" "zookeeper" {
  name = "${lower(var.company)}-${lower(var.project)}-zookeeper"
  subnets = [
    "${var.private_subnet_ids}"]

  internal = true

  security_groups = [
    "${aws_security_group.storage-baremetal.id}"]

  listener {
    instance_port = "${var.zookeeper_port}"
    instance_protocol = "tcp"
    lb_port = "${var.zookeeper_port}"
    lb_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 15
    target = "TCP:${var.zookeeper_port}"
    interval = 30
  }

  instances = [
    "${aws_instance.zookeeper.*.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "zookeeper-lb.${lower(var.project)}.${lower(var.company)}.io"
  }
}

output "zookeeper_elb_dns" {
  value = "${aws_elb.zookeeper.dns_name}"
}

output "zookeeper01_dns" {
  value = "${element(aws_instance.zookeeper.*.private_dns, 0)}"
}

output "zookeeper02_dns" {
  value = "${var.zookeeper_clustering ? element(aws_instance.zookeeper.*.private_dns, 1)  : "\"\""}"
}

output "zookeeper03_dns" {
  value = "${var.zookeeper_clustering ? element(aws_instance.zookeeper.*.private_dns, 2)  : "\"\""}"
}

output "zookeeper01_private_ip" {
  value = "${element(aws_instance.zookeeper.*.private_ip, 0)}"
}

output "zookeeper02_private_ip" {
  value = "${var.zookeeper_clustering ? element(aws_instance.zookeeper.*.private_ip, 1)  : "\"\""}"
}

output "zookeeper03_private_ip" {
  value = "${var.zookeeper_clustering ? element(aws_instance.zookeeper.*.private_ip, 2)  : "\"\""}"
}
