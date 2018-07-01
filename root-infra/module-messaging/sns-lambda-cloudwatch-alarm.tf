variable "slack_webhook_url" {}
variable "slack_webhook_channel" {}

locals {
  lambda_name_cloudwatch_alarm_sns_to_slack = "${var.company}-${var.project}-Cloudwatch-SendAlarmToSlack"
}

module "sns_to_slack" {
  source = "github.com/builtinnya/aws-sns-slack-terraform/module"

  slack_webhook_url = "${var.slack_webhook_url}"
  slack_channel_map = {
    "${aws_sns_topic.cloudwatch_alarm.name}" = "${var.slack_webhook_channel}"
  }

  # The following variables are optional.
  lambda_function_name = "${local.lambda_name_cloudwatch_alarm_sns_to_slack}"
  lambda_iam_role_name = "${var.company}-${var.project}_Lambda-CloudwatchAlarm"
  lambda_iam_policy_name = "${var.company}-${var.project}_Lambda-CloudwatchAlarm"
  default_username = "(AWS) ${var.company}/${var.project}" # doesnt work :(
  default_channel = "${var.slack_webhook_channel}"
  default_emoji = ":this_is_fine:"
}

resource "aws_lambda_permission" "allow_lambda_to_be_invoked_from_sns" {
  count = "${var.slack_alert_enable ? 0 : 1}"
  statement_id = "AllowSNSToSlackExecutionFromSNS"
  action = "lambda:invokeFunction"
  function_name = "${module.sns_to_slack.lambda_function_arn}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.cloudwatch_alarm.arn}"
}

resource "aws_sns_topic_subscription" "cloudwatch_alarm_subscription_lambda_slack" {
  topic_arn = "${aws_sns_topic.cloudwatch_alarm.arn}"
  protocol = "lambda"
  endpoint = "${module.sns_to_slack.lambda_function_arn}"
}

resource "aws_cloudwatch_log_group" "lambda_sns_to_slack" {
  name              = "/aws/lambda/${local.lambda_name_cloudwatch_alarm_sns_to_slack}"
  retention_in_days = 14
}
