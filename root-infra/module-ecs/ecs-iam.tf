variable "instance_purpose" {
  default = "Container"
}

data "aws_ami" "ecs" {
  most_recent = true
  owners = [
    "amazon"]

  filter {
    name = "name"
    values = [
      "amzn-ami-*.f-amazon-ecs-optimized"]
  }
}

resource "aws_iam_role" "ecs" {
  name = "${var.company}-${var.project}-ECS_${var.instance_purpose}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# policy for Cloudwatch EC2 Custom Metrics

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_custom_metric" {
  role = "${aws_iam_role.ecs.name}"
  policy_arn = "${var.iam_policy_ec2_cloudwatch_arn}"
}

# policy for ECS Operation

data "aws_iam_policy" "aws_managec_ecs" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_function" {
  role = "${aws_iam_role.ecs.name}"
  policy_arn = "${data.aws_iam_policy.aws_managec_ecs.arn}"
}

# policy for Sending ECS logs to cloudwatch

resource "aws_iam_policy" "ecs_cloudwatch_log" {
  name = "${var.company}-${var.project}-ECSCloudwatch_Log"
  path = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_log" {
  role = "${aws_iam_role.ecs.name}"
  policy_arn = "${aws_iam_policy.ecs_cloudwatch_log.arn}"
}

# Instance Profile for ECS

resource "aws_iam_instance_profile" "ecs" {
  name = "${var.company}-${var.project}-ECS_${var.instance_purpose}"
  role = "${aws_iam_role.ecs.name}"
}
