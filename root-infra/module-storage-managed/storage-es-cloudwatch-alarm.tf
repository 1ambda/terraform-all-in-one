data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_metric_alarm" "es-alert_Has-UnvailableNode" {
  alarm_name = "${var.company}/${var.project}-ES-Has_UnvailableNode"
  comparison_operator = "LessThanThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Maximum"
  threshold = "1"
  alarm_description = ""

  metric_name = "Nodes"
  namespace = "AWS/ES"
  dimensions = {
    DomainName = "${aws_elasticsearch_domain.search_cluster.domain_name}"
    ClientId = "${data.aws_caller_identity.current.account_id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "es-alert_ClusterStatus-RED" {
  alarm_name = "${var.company}/${var.project}-ES-ClusterStatus_RED"
  comparison_operator = "GreaterThanThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Maximum"
  threshold = "1"
  alarm_description = ""

  metric_name = "ClusterStatus.red"
  namespace = "AWS/ES"
  dimensions = {
    DomainName = "${aws_elasticsearch_domain.search_cluster.domain_name}"
    ClientId = "${data.aws_caller_identity.current.account_id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "es-alert_High-CPUUtilization" {
  alarm_name = "${var.company}/${var.project}-ES-High_CPUUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "80"
  alarm_description = ""

  metric_name = "CPUUtilization"
  namespace = "AWS/ES"
  dimensions = {
    DomainName = "${aws_elasticsearch_domain.search_cluster.domain_name}"
    ClientId = "${data.aws_caller_identity.current.account_id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "es-alert_High-JVMMemoryPressure" {
  alarm_name = "${var.company}/${var.project}-ES-High_JVMMemPres"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "50"
  alarm_description = ""

  metric_name = "JVMMemoryPressure"
  namespace = "AWS/ES"
  dimensions = {
    DomainName = "${aws_elasticsearch_domain.search_cluster.domain_name}"
    ClientId = "${data.aws_caller_identity.current.account_id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "es-alert_Low-FreeDiskSpcae" {
  alarm_name = "${var.company}/${var.project}-ES-Low_FreeDisk"
  comparison_operator = "LessThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Minimum"
  threshold = "10000"
  # 10 GB
  alarm_description = ""

  metric_name = "FreeStorageSpace"
  namespace = "AWS/ES"
  dimensions = {
    DomainName = "${aws_elasticsearch_domain.search_cluster.domain_name}"
    ClientId = "${data.aws_caller_identity.current.account_id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}
