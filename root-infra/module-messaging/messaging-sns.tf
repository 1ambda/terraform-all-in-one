resource "aws_sns_topic" "cloudwatch_alarm" {
  name = "${var.company}-${var.project}_Cloudwatch-Alarm"
}

resource "aws_sns_topic" "asg-event" {
  name = "${var.company}-${var.project}_ASG-Event"
}

output "sns_topic_arn_cloudwatch_alarm" {
  value = "${aws_sns_topic.cloudwatch_alarm.arn}"
}

output "sns_topic_arn_asg_event" {
  value = "${aws_sns_topic.asg-event.arn}"
}

