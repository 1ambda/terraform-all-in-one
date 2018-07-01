variable "asg_cooldown" {}
variable "asg_min_size" {}
variable "asg_max_size" {}
variable "asg_desired_capacity" {}
variable "asg_instance_type" {}

variable "ecs_host_root_disk_size" {}
variable "ecs_container_total_disk_size" {}
variable "ecs_container_per_disk_size" {}
variable "ecs_task_cleanup_duration" {}
variable "ecs_image_minimum_cleanup_age" {}

locals {
  instance_name = "ecs.${lower(var.project)}.${lower(var.company)}.io"
  asg_tf_resource_name = "ASG-${var.company}-${var.project}_ecs"
  cluster_name = "${var.company}-${var.project}_ecs"
}

output ecs_instance_name {
  value = "${local.instance_name}"
}

output "ecs_lc_name" {
  value = "${aws_launch_configuration.ecs.name}"
}

output "ecs_lc_id" {
  value = "${aws_launch_configuration.ecs.id}"
}

output "ecs_asg_id" {
  value = "${aws_autoscaling_group.ecs.id}"
}

output "ecs_asg_name" {
  value = "${aws_autoscaling_group.ecs.name}"
}

output "ecs_asg_arn" {
  value = "${aws_autoscaling_group.ecs.arn}"
}

## refactor

resource "aws_launch_configuration" "ecs" {
  name_prefix = "${local.instance_name}-"
  image_id = "${data.aws_ami.ecs.id}"
  instance_type = "${var.on_testing ? "t2.nano" : var.asg_instance_type }"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  key_name = "${var.aws_key_pair_name}"
  security_groups = [
    "${aws_security_group.ecs.id}"]
  user_data = "${data.template_cloudinit_config.ecs_user_data.rendered}"

  associate_public_ip_address = false
  ebs_optimized = false

  root_block_device = [
    {
      volume_size = "${var.on_testing ? "30" : var.ecs_host_root_disk_size }"
      volume_type = "gp2"
    },
  ]
  ebs_block_device = [
    {
      device_name = "/dev/xvdcz"
      volume_type = "gp2"
      volume_size = "${var.on_testing ? "100" : var.ecs_container_total_disk_size }"
      delete_on_termination = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name_prefix = "${local.instance_name}-"
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  vpc_zone_identifier = [
    "${var.private_subnet_ids}",
  ]

  min_size = "${var.asg_min_size}"
  max_size = "${var.asg_max_size}"
  desired_capacity = "${var.asg_desired_capacity}"

  health_check_type = "EC2"
  health_check_grace_period = 300
  default_cooldown = "${var.asg_cooldown}"

  enabled_metrics = []
  wait_for_capacity_timeout = "10m"
  protect_from_scale_in = false

  tags = [
    {
      key = "Terraform"
      value = "true"
      propagate_at_launch = true
    },
    {
      key = "Environment"
      value = "${var.environment}"
      propagate_at_launch = true
    },
    {
      key = "Company"
      value = "${var.company}"
      propagate_at_launch = true
    },
    {
      key = "Project"
      value = "${var.project}"
      propagate_at_launch = true
    },
    {
      key = "Name"
      value = "${local.instance_name}"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      "min_sizde", "max_size", "desired_capacity",
    ]
  }

  depends_on = [
    "aws_cloudwatch_log_group.ecs_agent",
    "aws_cloudwatch_log_group.ecs_audit",
    "aws_cloudwatch_log_group.ecs_dmesg",
    "aws_cloudwatch_log_group.ecs_docker",
    "aws_cloudwatch_log_group.ecs_init",
    "aws_cloudwatch_log_group.ecs_messages",
  ]
}

