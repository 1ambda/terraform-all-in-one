data "template_file" "terraform_kubernetes_variable" {
  template = <<EOT
variable "region" {
  default = "${var.region}"
}
variable "company" {
  default = "${var.company}"
}
variable "project" {
  default = "${var.project}"
}
variable "environment" {
  default = "${var.environment}"
}
variable "on_testing" {
  default = "${var.on_testing}"
}

variable "slack_webhook_url_alert" {
  default = "${local.slack_webhook_url_alert}"
}
variable "slack_webhook_channel_alert" {
  default = "${local.slack_webhook_channel_alert}"
}
variable "iam_policy_ec2_cloudwatch_arn" {
  default = "${module.module-iam.iam_policy_ec2_cloudwatch_arn}"
}
variable "sns_topic_cloudwatch_alarm_arn" {
  default = "${module.module-messaging.sns_topic_arn_cloudwatch_alarm}"
}
variable "sns_topic_arn_asg_event" {
  default = "${module.module-messaging.sns_topic_arn_asg_event}"
}

variable "ec_port" {
   default = "${module.module-storage-managed.ec_port}"
}
variable "ec_dns" {
  default = "${module.module-storage-managed.ec_dns}"
}
variable "es_port" {
  default = "${module.module-storage-managed.es_port}"
}
variable "es_http_port" {
  default = "${module.module-storage-managed.es_http_port}"
}
variable "es_dns" {
  default = "${module.module-storage-managed.es_dns}"
}
variable "rds_port" {
  default = "${module.module-storage-managed.rds_port}"
}
variable "rds_dns" {
  default = "${module.module-storage-managed.rds_dns}"
}
variable "zookeeper_port" {
  default = "${module.module-storage-baremetal.zookeeper_port}"
}
variable "zookeeper_dns_list" {
  type = "list"
  default = [${join(",", formatlist("\"%s\"", module.module-storage-baremetal.zookeeper_dns_list))}]
}

variable "bastion_security_group_id" {
  default = "${module.module-bastion.bastion_security_group_id}"
}
variable "managed_storage_security_group_id" {
  default = "${module.module-storage-managed.storage-managed_security_group_id}"
}
variable "baremetal_storage_security_group_id" {
  default = "${module.module-storage-baremetal.storage-baremetal_security_group_id}"
}
variable "ecs_security_group_id" {
  default = "${module.module-ecs.ecs_security_group_id}"
}

variable "whitelist_enabled" {
  default = "${local.whitelist_enabled}"
}
variable "whitelist_targets" {
  type = "list"
  default = [${join(",", formatlist("\"%s\"", local.whitelist_targets))}]
}

variable "domain_name" {
  default = "${local.domain_name}"
}
variable "external_acm_use" {
  default = ${local.external_acm_use}
}
variable "external_acm_arn" {
  default = "${local.external_acm_arn}"
}

variable "local_acm_arm" {
  default = "${module.module-kops.local_acm_arm}"
}

EOT
}

resource "null_resource" "template_terraform_kubernetes_variable" {
  triggers {
    # uuid = "${uuid()}" # for debug
    output = "${data.template_file.terraform_kubernetes_variable.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT

    echo '${data.template_file.terraform_kubernetes_variable.rendered}' > ${path.root}/../root-kubernetes/generated.variable.tf
EOT
  }
}
