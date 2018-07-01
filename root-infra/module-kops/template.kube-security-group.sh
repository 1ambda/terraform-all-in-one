# Kubernetes Master

resource "aws_security_group_rule" "storage-managed_allow_rds_from_kube_master" {
  source_security_group_id = "$${aws_security_group.masters-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.managed_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.rds_port}"
  to_port = "$${var.rds_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "storage-managed_allow_ec_from_kube_master" {
  source_security_group_id = "$${aws_security_group.masters-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.managed_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.ec_port}"
  to_port = "$${var.ec_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "storage-managed_allow_es_from_kube_master" {
  source_security_group_id = "$${aws_security_group.masters-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.managed_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.es_port}"
  to_port = "$${var.es_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "storage-baremetal_allow_zookeeper_from_kube_master" {
  source_security_group_id = "$${aws_security_group.masters-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.baremetal_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.zookeeper_port}"
  to_port = "$${var.zookeeper_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "ecs_allow_all_from_kube_master" {
  source_security_group_id = "$${aws_security_group.masters-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.ecs_security_group_id}"

  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
}

resource "aws_security_group_rule" "kube_master_allow_ssh_from_ssh" {
  source_security_group_id = "$${var.bastion_security_group_id}"
  security_group_id = "$${aws_security_group.masters-kops-${project}-${company}-k8s-local.id}"

  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "tcp"
}

# Kubernetes Worker

resource "aws_security_group_rule" "storage-managed_allow_rds_from_kube_worker" {
  source_security_group_id = "$${aws_security_group.nodes-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.managed_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.rds_port}"
  to_port = "$${var.rds_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "storage-managed_allow_ec_from_kube_worker" {
  source_security_group_id = "$${aws_security_group.nodes-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.managed_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.ec_port}"
  to_port = "$${var.ec_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "storage-managed_allow_es_from_kube_worker" {
  source_security_group_id = "$${aws_security_group.nodes-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.managed_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.es_port}"
  to_port = "$${var.es_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "storage-baremetal_allow_zookeeper_from_kube_worker" {
  source_security_group_id = "$${aws_security_group.nodes-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.baremetal_storage_security_group_id}"

  type = "ingress"
  from_port = "$${var.zookeeper_port}"
  to_port = "$${var.zookeeper_port}"
  protocol = "tcp"
}

resource "aws_security_group_rule" "ecs_allow_all_from_kube_worker" {
  source_security_group_id = "$${aws_security_group.nodes-kops-${project}-${company}-k8s-local.id}"
  security_group_id = "$${var.ecs_security_group_id}"

  type = "ingress"
  from_port = 0
  to_port = 0
  protocol = "-1"
}

resource "aws_security_group_rule" "kube_worker_allow_ssh_from_ssh" {
  source_security_group_id = "$${var.bastion_security_group_id}"
  security_group_id = "$${aws_security_group.nodes-kops-${project}-${company}-k8s-local.id}"

  type = "ingress"
  from_port = "22"
  to_port = "22"
  protocol = "tcp"
}
