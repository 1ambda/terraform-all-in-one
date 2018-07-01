resource "aws_autoscaling_notification" "ecs_asg_event_notification" {
  group_names = [
    "${aws_autoscaling_group.ecs.name}",
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = "${var.sns_topic_arn_asg_event}"
}
