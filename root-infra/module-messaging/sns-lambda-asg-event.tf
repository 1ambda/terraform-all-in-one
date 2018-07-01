locals {
  lambda_name_asg_event_cloudwatch_manager = "${var.company}-${var.project}_ASG-CloudwatchAlarmManager"
  lambda_role_asg_event_cloudwatch_manager = "${var.company}-${var.project}_Lambda-ASGCloudwatchAlarmManager"
  lambda_function_dir = "${path.module}/lambda-asg-event"
}

data "aws_iam_policy_document" "lambda_sns_asg_event" {
  statement {
    actions = [
      "sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"]
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_asg_event_cloudwatch_manager" {
  name              = "/aws/lambda/${local.lambda_name_asg_event_cloudwatch_manager}"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda_sns_asg_event" {
  name = "${local.lambda_role_asg_event_cloudwatch_manager}"

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

resource "aws_iam_role_policy" "lambda_sns_asg_event" {
  name = "${local.lambda_role_asg_event_cloudwatch_manager}"
  role = "${aws_iam_role.lambda_sns_asg_event.id}"
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
    },
    {
        "Effect": "Allow",
        "Action": [
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:EnableAlarmActions",
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DisableAlarmActions"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

data "archive_file" "lambda_sns_asg_event" {
  type = "zip"
  source_file = "${local.lambda_function_dir}/main.py"
  output_path = "${local.lambda_function_dir}/function.zip"
}

resource "aws_lambda_function" "asg_event_to_slack_with_cloudwatch_management" {
  filename = "${data.archive_file.lambda_sns_asg_event.output_path}"
  source_code_hash = "${data.archive_file.lambda_sns_asg_event.output_base64sha256}"
  function_name = "${local.lambda_name_asg_event_cloudwatch_manager}"
  role = "${aws_iam_role.lambda_sns_asg_event.arn}"

  # {file_name}.{function_name}
  handler = "main.lambda_handler"
  runtime = "python2.7"

  timeout = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "https://${var.slack_webhook_url}"
      SLACK_WEBHOOK_CHANNEL = "${var.slack_webhook_channel}"
      SLACK_WEBHOOK_ASG_BOT_NAME = "AWS AutoScaling"
      SLACK_WEBHOOK_ASG_BOT_EMOJI = ":this_is_fine:"
      SLACK_WEBHOOK_CL_BOT_NAME = "AWS CloudWatch API"
      SLACK_WEBHOOK_CL_BOT_EMOJI = ":this_is_fine:"
      CLOUDWATCH_TARGET_SNS_ARN = "${aws_sns_topic.cloudwatch_alarm.arn}"
      CLOUDWATCH_ALERT_REGION = "${var.region}"
      META_COMPANY = "${var.company}"
      META_PROJECT = "${var.project}"
      ENV = "AWS"
    }
  }

  lifecycle {
    ignore_changes = []
  }

  depends_on = ["aws_cloudwatch_log_group.lambda_asg_event_cloudwatch_manager"]
}

# SNS Subscription

resource "aws_lambda_permission" "subscription_for_asg_event_sns" {
  count = "${var.slack_alert_enable ? 0 : 1}"

  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.asg_event_to_slack_with_cloudwatch_management.function_name}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.asg-event.arn}"
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = "${aws_sns_topic.asg-event.arn}"
  protocol = "lambda"
  endpoint = "${aws_lambda_function.asg_event_to_slack_with_cloudwatch_management.arn}"
}
