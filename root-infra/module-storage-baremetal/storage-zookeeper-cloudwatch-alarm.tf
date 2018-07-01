variable "storage_zookeeper_storage_root_block_name" {
  default = "/dev/xvda1"
}

resource "aws_cloudwatch_metric_alarm" "storage-baremetal-zookeeper-alert_High-CPUUtilization" {
  count = "${aws_instance.zookeeper.count}"

  alarm_name = "${var.company}/${var.project}-StorageZookeeper${format("%02d", count.index + 1)}-High_CPUUtil"
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
    InstanceId = "${element(aws_instance.zookeeper.*.id, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "storage-baremetal-zookeeper-alert_Has-SystemCheckFailure" {
  count = "${aws_instance.zookeeper.count}"

  alarm_name = "${var.company}/${var.project}-StorageZookeeper${format("%02d", count.index + 1)}-Has_SysCheckFailure"
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
    InstanceId = "${element(aws_instance.zookeeper.*.id, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

# EC2 Custom Metric (Disk, Memory)

resource "aws_cloudwatch_metric_alarm" "storage-baremetal-zookeeper-alert_High-RootDiskUtil" {
  count = "${aws_instance.zookeeper.count}"

  alarm_name = "${var.company}/${var.project}-StorageZookeeper${format("%02d", count.index + 1)}-High_RootDiskUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Maximum"
  threshold = "80"
  alarm_description = ""

  metric_name = "DiskSpaceUtilization"
  namespace = "System/Linux"
  dimensions = {
    InstanceId = "${element(aws_instance.zookeeper.*.id, count.index)}"
    MountPath = "/"
    Filesystem = "${var.storage_zookeeper_storage_root_block_name}"
  }

  actions_enabled = true
  insufficient_data_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "storage-baremetal-zookeeper-alert_High-MemUtil" {
  count = "${aws_instance.zookeeper.count}"

  alarm_name = "${var.company}/${var.project}-StorageZookeeper${format("%02d", count.index + 1)}-High_MemUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Maximum"
  threshold = "80"
  alarm_description = ""

  metric_name = "MemoryUtilization"
  namespace = "System/Linux"
  dimensions = {
    InstanceId = "${element(aws_instance.zookeeper.*.id, count.index)}"
  }

  actions_enabled = true
  insufficient_data_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

# ELB

resource "aws_cloudwatch_metric_alarm" "elb-storage-zookeeper-alert_Has-UnHealthyHostCount" {
  alarm_name = "${var.company}/${var.project}-ZookeeperELB-Has_UnhealthyHost"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Maximum"
  threshold = "1"
  alarm_description = ""

  metric_name = "UnHealthyHostCount"
  namespace = "AWS/ELB"
  dimensions = {
    LoadBalancerName = "${aws_elb.zookeeper.name}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "elb-storage-zookeeper-alert_High-BackendConnectionErrors" {
  alarm_name = "${var.company}/${var.project}-ZookeeperELB-High_BackendConnErr"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Sum"
  threshold = "1"
  alarm_description = ""

  # Missing data points are treated as being within the threshold
  treat_missing_data = "notBreaching"

  metric_name = "BackendConnectionErrors"
  namespace = "AWS/ELB"
  dimensions = {
    LoadBalancerName = "${aws_elb.zookeeper.name}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "elb-storage-zookeeper-alert_High-SpilloverCount" {
  alarm_name = "${var.company}/${var.project}-ZookeeperELB-High_ReqSpillOver"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Sum"
  threshold = "1"
  alarm_description = ""

  # Missing data points are treated as being within the threshold
  treat_missing_data = "notBreaching"

  metric_name = "SpilloverCount"
  namespace = "AWS/ELB"
  dimensions = {
    LoadBalancerName = "${aws_elb.zookeeper.name}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}
