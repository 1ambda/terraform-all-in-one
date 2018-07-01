
# ASG Policies

resource "aws_autoscaling_policy" "ecs-asg_decrease" {
  name = "${var.company}/${var.project}-ECS-ASG_Decrease"
  policy_type = "SimpleScaling"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.ecs.name}"
}

resource "aws_autoscaling_policy" "ecs-asg_increase" {
  name = "${var.company}/${var.project}-ECS-ASG_Increase"
  policy_type = "SimpleScaling"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.ecs.name}"
}