resource "aws_cloudwatch_metric_alarm" "rds_mariadb-alert_High-CPUUtilization" {
  alarm_name = "${var.company}/${var.project}-RDSHub-High_CPUUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "80"
  alarm_description = ""

  metric_name = "CPUUtilization"
  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = "${aws_db_instance.rds_mariadb.id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "rds_mariadb-alert_High-DBConnections" {
  alarm_name = "${var.company}/${var.project}-RDSHub-High_DBConn"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Maximum"
  threshold = "40"
  alarm_description = ""

  metric_name = "DatabaseConnections"
  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = "${aws_db_instance.rds_mariadb.id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "rds_mariadb-alert_Low-FreeDiskSpace" {
  alarm_name = "${var.company}/${var.project}-RDSHub-Low_FreeDisk"
  comparison_operator = "LessThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Minimum"
  threshold = "5000000000"
  # 5 GB
  alarm_description = ""

  metric_name = "FreeStorageSpace"
  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = "${aws_db_instance.rds_mariadb.id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "rds_mariadb-alert_Low-FreeMemory" {
  alarm_name = "${var.company}/${var.project}-RDSHub-Low_FreeMem"
  comparison_operator = "LessThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Minimum"
  threshold = "100000000"
  # 100 MB
  alarm_description = ""

  metric_name = "FreeableMemory"
  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = "${aws_db_instance.rds_mariadb.id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "rds_mariadb-alert-High_SwapUsage" {
  alarm_name = "${var.company}/${var.project}-RDSHub-High_SwapUsage"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Maximum"
  threshold = "20000000"
  # 20 MB
  alarm_description = ""

  metric_name = "SwapUsage"
  namespace = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = "${aws_db_instance.rds_mariadb.id}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}
