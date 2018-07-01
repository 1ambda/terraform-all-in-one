resource "aws_iam_role" "lambda_ecs_event" {
  name = "${var.company}-${var.project}_Lambda-ECSEvent"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_ecs_event" {
  name = "${var.company}-${var.project}_Lambda-ECSEvent"
  path = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_ecs_event" {
  role = "${aws_iam_role.lambda_ecs_event.name}"
  policy_arn = "${aws_iam_policy.lambda_ecs_event.arn}"
}
