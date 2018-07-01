# (Kubernetes Master) Defualt Metrics

locals {
  # could be multiple in case of HA-ed cluster setup
  kube_master_asg_group_names = [
    "${local.kube_master_asg_name}"
  ]

  kube_worker_asg_group_names = [
    "${local.kube_worker_asg_name}"
  ]
}

resource "aws_cloudwatch_metric_alarm" "kube-master-asg-alert_High-CPUUtilization" {
  count = "${length(local.kube_master_asg_group_names)}"

  alarm_name = "${var.company}/${var.project}-KubeMasterASG${format("%02d", count.index + 1)}-High_CPUUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Average"
  threshold = "80"
  alarm_description = ""

  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = "${element(local.kube_master_asg_group_names, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}",
  ]
}

resource "aws_cloudwatch_metric_alarm" "kube-master-asg-alert_Has-SystemCheckFailure" {
  count = "${length(local.kube_master_asg_group_names)}"

  alarm_name = "${var.company}/${var.project}-KubeMasterASG${format("%02d", count.index + 1)}-Has_SysCheckFailure"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Sum"
  threshold = "1"
  alarm_description = ""

  metric_name = "StatusCheckFailed"
  namespace = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = "${element(local.kube_master_asg_group_names, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}",
  ]
}

# (Kubernetes Worker) Defualt Metrics

resource "aws_cloudwatch_metric_alarm" "kube-worker-asg-alert_High-CPUUtilization" {
  count = "${length(local.kube_worker_asg_group_names)}"

  alarm_name = "${var.company}/${var.project}-KubeWorkerASG-High_CPUUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Average"
  threshold = "80"
  alarm_description = ""

  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = "${element(local.kube_worker_asg_group_names, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}",
  ]
}

resource "aws_cloudwatch_metric_alarm" "kube-worker-asg-alert_Has-SystemCheckFailure" {
  count = "${length(local.kube_worker_asg_group_names)}"
  alarm_name = "${var.company}/${var.project}-KubeWorkerASG-Has_SysCheckFailure"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Sum"
  threshold = "1"
  alarm_description = ""

  metric_name = "StatusCheckFailed"
  namespace = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = "${element(local.kube_worker_asg_group_names, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}",
  ]
}

# (Kubernetes Master + Worker) Send ASG Notification to SNS for Custom Metrics

resource "aws_autoscaling_notification" "kube_worker_asg_event_notification" {
  group_names = [
    "${concat(local.kube_master_asg_group_names, local.kube_worker_asg_group_names)}"
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "${var.sns_topic_arn_asg_event}"
}