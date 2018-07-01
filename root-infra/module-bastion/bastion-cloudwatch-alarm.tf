variable "sns_topic_cloudwatch_alarm_arn" {}

resource "aws_cloudwatch_metric_alarm" "bastion-asg-alert_Has-SystemCheckFailure" {
  alarm_name = "${var.company}/${var.project}-Bastion-Has_SysCheckFailure"
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
    InstanceId = "${aws_instance.bastion.id}"
  }

  actions_enabled = true
  insufficient_data_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"
  ]
  ok_actions = []
  alarm_actions = [
    "${var.sns_topic_cloudwatch_alarm_arn}"
  ]
}
