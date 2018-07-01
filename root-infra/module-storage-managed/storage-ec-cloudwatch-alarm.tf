resource "aws_cloudwatch_metric_alarm" "ec-alert_High-CPUUtilization" {
  count = "${aws_elasticache_replication_group.redis.number_cache_clusters}"

  alarm_name = "${var.company}/${var.project}-EC-${format("%03d", count.index + 1)}-High_CPUUtil"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "50"
  alarm_description = ""

  metric_name = "CPUUtilization"
  namespace = "AWS/ElastiCache"
  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-${format("%03d", count.index + 1)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ec-alert_Low-FreeMemory" {
  count = "${aws_elasticache_replication_group.redis.number_cache_clusters}"

  alarm_name = "${var.company}/${var.project}-EC-${format("%03d", count.index + 1)}-FreeMemory"
  comparison_operator = "LessThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Minimum"
  threshold = "200000000"
  # 200 MB
  alarm_description = ""

  metric_name = "FreeableMemory"
  namespace = "AWS/ElastiCache"
  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-${format("%03d", count.index + 1)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ec-alert_Has-SwapUsage" {
  count = "${aws_elasticache_replication_group.redis.number_cache_clusters}"

  alarm_name = "${var.company}/${var.project}-EC-${format("%03d", count.index + 1)}-Has_SwapUsage"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Maximum"
  threshold = "2000000"
  # 2 MB
  alarm_description = ""

  metric_name = "SwapUsage"
  namespace = "AWS/ElastiCache"
  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-${format("%03d", count.index + 1)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ec-alert_High-CurrentConnections" {
  count = "${aws_elasticache_replication_group.redis.number_cache_clusters}"

  alarm_name = "${var.company}/${var.project}-EC-${format("%03d", count.index + 1)}-High_CurrConns"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Maximum"
  threshold = "70"
  alarm_description = ""

  metric_name = "CurrConnections"
  namespace = "AWS/ElastiCache"
  dimensions = {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-${format("%03d", count.index + 1)}"
  }

  actions_enabled = true
  insufficient_data_actions = []
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"]
}