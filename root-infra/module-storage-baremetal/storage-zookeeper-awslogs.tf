locals {
  cloudwatch_awslogs_zookeeper_prefix = "zookeeper.${lower(var.project)}.${lower(var.company)}.io"
}

resource "aws_cloudwatch_log_group" "zookeeper_storage_log" {
  name = "/${local.cloudwatch_awslogs_zookeeper_prefix}/var/log/zookeeper/zookeeper.log"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "zookeeper_instance_message" {
  name = "/${local.cloudwatch_awslogs_zookeeper_prefix}/var/log/messages"
  retention_in_days = 7
}

data "template_file" "zookeeper_userdata_awslogs" {
  template = "${file("${path.root}/../template/template.amazonlinux-awslogs.sh")}"

  vars {
    awslogs_stream_prefix = "${local.cloudwatch_awslogs_zookeeper_prefix}"
    storage_log_path = "var/log/zookeeper/zookeeper.log"
    region = "${var.region}"
  }
}

