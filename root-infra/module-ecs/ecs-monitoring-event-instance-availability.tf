locals {
  lambda_name_ecs_event_instance_availability = "${var.company}-${var.project}_ECS-InstanceAvailability"
}

resource "aws_cloudwatch_event_rule" "ecs_event_instance" {
  name = "${local.lambda_name_ecs_event_instance_availability}"
  description = ""

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Container Instance State Change"
  ],
  "detail": {
    "clusterArn": [
      "${aws_ecs_cluster.interpreter.arn}"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "ecs_event_instance_availability" {
  rule = "${aws_cloudwatch_event_rule.ecs_event_instance.name}"
  arn = "${aws_lambda_function.handler_ecs_event_instance_availability.arn}"
}

# Lambda

data "archive_file" "lambda_zip_ecs_event_instance_availability" {
  type = "zip"
  source_file = "${path.module}/lambda-ecs-event-instance-availability/main.py"
  output_path = "${path.module}/lambda-ecs-event-instance-availability/function.zip"
}

resource "aws_lambda_permission" "ecs_event_instance_availability" {
  count = "${var.on_testing ? 0 : 1}"

  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.handler_ecs_event_instance_availability.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.ecs_event_instance.arn}"
}

resource "aws_cloudwatch_log_group" "lambda_ecs_event_instance_availability" {
  name              = "/aws/lambda/${local.lambda_name_ecs_event_instance_availability}"
  retention_in_days = 14
}

resource "aws_lambda_function" "handler_ecs_event_instance_availability" {
  filename = "${data.archive_file.lambda_zip_ecs_event_instance_availability.output_path}"
  source_code_hash = "${data.archive_file.lambda_zip_ecs_event_instance_availability.output_base64sha256}"
  function_name = "${local.lambda_name_ecs_event_instance_availability}"
  role = "${aws_iam_role.lambda_ecs_event.arn}"

  depends_on = ["aws_cloudwatch_log_group.lambda_ecs_event_instance_availability"]

  # {file_name}.{function_name}
  handler = "main.lambda_handler"
  runtime = "python2.7"
  timeout = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "https://${var.slack_webhook_url_alert}"
      SLACK_WEBHOOK_CHANNEL = "${var.slack_webhook_channel_alert}"
      SLACK_WEBHOOK_BOT_NAME = "AWS ECS Event (Instance Availability)"
      SLACK_WEBHOOK_BOT_EMOJI = ":this_is_fine:"
      ECS_CLUSTER_NAME = "${aws_ecs_cluster.interpreter.name}"
      CURRENT_AWS_REGION = "${var.region}"
      META_COMPANY = "${var.company}"
      META_PROJECT = "${var.project}"
      ENV = "AWS"
    }
  }

  lifecycle {
    ignore_changes = []
  }

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    # belongs to the ecs resource
    Name = "ecs.${lower(var.project)}.${lower(var.company)}.io"
  }
}


