variable "log_path_daemon" {
  default = "/var/log/daemon.log"
}

variable "log_path_etcd" {
  default = "/var/log/etcd.log"
}

variable "log_path_etcdevent" {
  default = "/var/log/etcd-events.log"
}

variable "log_path_kubeproxy" {
  default = "/var/log/kube-proxy.log"
}

variable "log_path_kubeapiserver" {
  default = "/var/log/kube-apiserver.log"
}

variable "log_path_kubeapiserveraudit" {
  default = "/var/log/kube-apiserver-audit.log"
}

variable "log_path_kubectrlmanager" {
  default = "/var/log/kube-controller-manager.log"
}

variable "log_path_kubescheduler" {
  default = "/var/log/kube-scheduler.log"
}

locals {
  awslogs_kube_worker_prefix = "/nodes.${var.kops_cluster_name}"
  awslogs_kube_master_prefix = "/masters.${var.kops_cluster_name}"

  kube_worker_awslogs_targets = [
    "${var.log_path_daemon}",
    "${var.log_path_kubeproxy}",]

  kube_master_awslogs_targets = [
    "${var.log_path_daemon}",
    "${var.log_path_etcd}",
    "${var.log_path_etcdevent}",
    "${var.log_path_kubeproxy}",
    "${var.log_path_kubeapiserver}",
    "${var.log_path_kubeapiserveraudit}",
    "${var.log_path_kubectrlmanager}",
    "${var.log_path_kubescheduler}",
  ]
}

# kubernetes worker

resource "aws_cloudwatch_log_group" "kube_worker_awslogs" {
  count = "${length(local.kube_worker_awslogs_targets)}"
  name = "${local.awslogs_kube_worker_prefix}${element(local.kube_worker_awslogs_targets, count.index)}"
  retention_in_days = 7
}

# kubernetes master

resource "aws_cloudwatch_log_group" "kube_master_awslogs" {
  count = "${length(local.kube_master_awslogs_targets)}"
  name = "${local.awslogs_kube_master_prefix}${element(local.kube_master_awslogs_targets, count.index)}"
  retention_in_days = 7
}


