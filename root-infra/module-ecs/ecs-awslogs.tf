resource "aws_cloudwatch_log_group" "ecs_dmesg" {
  name              = "/${local.instance_name}/var/log/dmesg"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_messages" {
  name              = "/${local.instance_name}/var/log/messages"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_docker" {
  name              = "/${local.instance_name}/var/log/docker"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_init" {
  name              = "/${local.instance_name}/var/log/ecs/ecs-init.log"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_agent" {
  name              = "/${local.instance_name}/var/log/ecs/ecs-agent.log"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_audit" {
  name              = "/${local.instance_name}/var/log/ecs/audit.log"
  retention_in_days = 14
}
