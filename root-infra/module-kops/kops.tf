locals {
  path_module_kubernetes = "${path.root}/../root-kubernetes"
  whitelist_allow_all = "\n  - 0.0.0.0/0"
  whitelist_specified = "${join("\n", formatlist("  - %s", var.whitelist_targets))}"
}

data "template_file" "kops_manifest" {
  template = "${file("${path.module}/template.kops-manifest.yaml")}"

  vars {
    region = "${var.region}"
    company = "${lower(var.company)}"
    project = "${lower(var.project)}"

    kops_ami = "${var.kops_ami}"
    kube_version = "${var.kube_version}"
    kops_cluster_name = "${var.kops_cluster_name}"

    vpc_id = "${var.vpc_id}"
    vpc_cidr = "${var.vpc_cidr}"
    vpc_az1 = "${element(var.availability_zones, 0)}"
    vpc_az2 = "${element(var.availability_zones, 1)}"

    private_subnet_id1 = "${element(var.private_subnet_ids, 0)}"
    private_subnet_id2 = "${element(var.private_subnet_ids, 1)}"
    public_subnet_id1 = "${element(var.public_subnet_ids, 0)}"
    public_subnet_id2 = "${element(var.public_subnet_ids, 1)}"

    private_subnet_cidr1 = "${element(var.private_subnets_cidr_blocks, 0)}"
    private_subnet_cidr2 = "${element(var.private_subnets_cidr_blocks, 1)}"
    public_subnet_cidr1 = "${element(var.public_subnets_cidr_blocks, 0)}"
    public_subnet_cidr2 = "${element(var.public_subnets_cidr_blocks, 1)}"

    master_instance_count = "${var.kube_master_instance_count}"
    master_instance_type = "${var.on_testing ? "t2.medium" : var.kube_master_instance_type}"
    master_root_volume_size = "${var.kube_master_root_volume_size}"

    worker_instance_count = "${var.kube_worker_instance_count}"
    worker_instance_type = "${var.on_testing ? "t2.medium" : var.kube_worker_instance_type}"
    worker_root_volume_size = "${var.kube_worker_root_volume_size}"

    # whitelist
    sshAccessBlock = "  sshAccess:\n  - ${var.bastion_public_ip}/32\n  - ${var.bastion_private_ip}/32"
    kubernetesApiAccess = "${var.whitelist_enabled == false ? "  kubernetesApiAccess:${local.whitelist_allow_all}" : "  kubernetesApiAccess:\n${local.whitelist_specified}"}"
  }
}

resource "null_resource" "template_kops" {
  triggers {
    # uuid = "${uuid()}" # for debug
    output = "${data.template_file.kops_manifest.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${data.template_file.kops_manifest.rendered}' > ${local.path_module_kubernetes}/generated.kops-manifest.yaml
EOT
  }
}

resource "null_resource" "template_kubernetes_output" {
  triggers {
    # uuid = "${uuid()}" # for debug
    company = "${lower(var.company)}"
    project = "${lower(var.project)}"
    availability_zones = "${join(",", var.availability_zones)}"
  }

  provisioner "local-exec" {
    command = <<EOT
    # output
    echo '' > ${local.path_module_kubernetes}/generated.output.tf

    echo 'output "kube_master_asg_name" {' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '  value = "$${aws_autoscaling_group.master-${element(var.availability_zones, 0)}-masters-kops-${lower(var.project)}-${lower(var.company)}-k8s-local.name}"' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '}' >> ${local.path_module_kubernetes}/generated.output.tf

    echo 'output "kube_worker_asg_name" {' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '  value = "$${aws_autoscaling_group.nodes-kops-${lower(var.project)}-${lower(var.company)}-k8s-local.name}"' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '}' >> ${local.path_module_kubernetes}/generated.output.tf

    echo 'output "kube_master_security_group_id" {' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '  value = "$${aws_security_group.masters-kops-${lower(var.project)}-${lower(var.company)}-k8s-local.id}"' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '}' >> ${local.path_module_kubernetes}/generated.output.tf

    echo 'output "kube_worker_security_group_id" {' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '  value = "$${aws_security_group.nodes-kops-${lower(var.project)}-${lower(var.company)}-k8s-local.id}"' >> ${local.path_module_kubernetes}/generated.output.tf
    echo '}' >> ${local.path_module_kubernetes}/generated.output.tf

    # local
    echo 'locals {' > ${local.path_module_kubernetes}/generated.local.tf
    echo '  kube_master_asg_name = "$${aws_autoscaling_group.master-${element(var.availability_zones, 0)}-masters-kops-${lower(var.project)}-${lower(var.company)}-k8s-local.name}"' >> ${local.path_module_kubernetes}/generated.local.tf
    echo '  kube_worker_asg_name = "$${aws_autoscaling_group.nodes-kops-${lower(var.project)}-${lower(var.company)}-k8s-local.name}"' >> ${local.path_module_kubernetes}/generated.local.tf
    echo '}' >> ${local.path_module_kubernetes}/generated.local.tf

EOT
  }
}

resource "null_resource" "template_kubernetes_kops_env" {
  triggers {
    # uuid = "${uuid()}" # for debug
    company = "${lower(var.company)}"
    project = "${lower(var.project)}"
    availability_zones = "${join(",", var.availability_zones)}"
  }

  provisioner "local-exec" {
    command = <<EOT

    echo '' > ${local.path_module_kubernetes}/generated.kops-env.sh
    echo 'export NAME=kops.${lower(var.project)}.${lower(var.company)}.k8s.local'  >> ${local.path_module_kubernetes}/generated.kops-env.sh
    echo 'export KOPS_STATE_STORE=s3://io.${lower(var.company)}.${lower(var.project)}.infra.kops-secret' >> ${local.path_module_kubernetes}/generated.kops-env.sh
    chmod +x ${local.path_module_kubernetes}/generated.kops-env.sh
EOT
  }
}

resource "null_resource" "template_kubernetes_kops_create_cluster" {
  triggers {
    # uuid = "${uuid()}" # for debug
    company = "${lower(var.company)}"
    project = "${lower(var.project)}"
    availability_zones = "${join(",", var.availability_zones)}"
  }

  provisioner "local-exec" {
    command = <<EOT

    echo '#!/bin/bash' > ${local.path_module_kubernetes}/generated.kops-create.sh
    echo '' >> ${local.path_module_kubernetes}/generated.kops-create.sh
    echo '$(cat generated.kops-env.sh)' >> ${local.path_module_kubernetes}/generated.kops-create.sh
    echo 'kops create -f ./generated.kops-manifest.yaml' >> ${local.path_module_kubernetes}/generated.kops-create.sh
    echo 'kops create secret sshpublickey --name $NAME admin -i ~/.ssh/key.${lower(var.project)}.${lower(var.company)}.io_rsa.pub' >> ${local.path_module_kubernetes}/generated.kops-create.sh
    echo 'kops update cluster --target=terraform --out=. $NAME' >> ${local.path_module_kubernetes}/generated.kops-create.sh
    chmod +x ${local.path_module_kubernetes}/generated.kops-create.sh
EOT
  }
}

resource "null_resource" "template_kubernetes_kops_delete_cluster" {
  triggers {
    # uuid = "${uuid()}" # for debug
    company = "${lower(var.company)}"
    project = "${lower(var.project)}"
  }

  provisioner "local-exec" {
    command = <<EOT

    echo '#!/bin/bash' > ${local.path_module_kubernetes}/generated.kops-delete.sh
    echo '' >> ${local.path_module_kubernetes}/generated.kops-delete.sh
    echo 'kubectl config delete-context kops.bank.kakao.enterprise.zepl.k8s.local' >> ${local.path_module_kubernetes}/generated.kops-delete.sh
    echo 'kubectl config delete-cluster kops.bank.kakao.enterprise.zepl.k8s.local' >> ${local.path_module_kubernetes}/generated.kops-delete.sh

    echo 'aws s3 rm --recursive s3://io.${lower(var.company)}.${lower(var.project)}.infra.kops-secret/' >> ${local.path_module_kubernetes}/generated.kops-delete.sh
    echo "versions=\$(aws s3api list-object-versions --bucket io.${lower(var.company)}.${lower(var.project)}.infra.kops-secret | jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')" >> ${local.path_module_kubernetes}/generated.kops-delete.sh
    echo 'aws s3api delete-objects --bucket io.enterprise.${lower(var.company)}.${lower(var.project)}.infra.kops-secret --delete $versions' >> ${local.path_module_kubernetes}/generated.kops-delete.sh

    chmod +x ${local.path_module_kubernetes}/generated.kops-delete.sh
EOT
  }
}

resource "null_resource" "template_kubernetes_kops_update_cluster" {
  triggers {
    # uuid = "${uuid()}" # for debug
  }

  provisioner "local-exec" {
    command = <<EOT

    echo '#!/bin/bash' > ${local.path_module_kubernetes}/generated.kops-update.sh
    echo '' >> ${local.path_module_kubernetes}/generated.kops-update.sh
    echo '$(cat generated.kops-env.sh)' >> ${local.path_module_kubernetes}/generated.kops-update.sh
    echo 'kops replace -f ./generated.kops-manifest.yaml' >> ${local.path_module_kubernetes}/generated.kops-update.sh
    echo 'kops update cluster --target=terraform --out=. $NAME' >> ${local.path_module_kubernetes}/generated.kops-update.sh

    chmod +x ${local.path_module_kubernetes}/generated.kops-update.sh
EOT
  }
}

data "template_file" "kubernetes_security_group" {
  template = "${file("${path.module}/template.kube-security-group.sh")}"

  vars {
    project = "${lower(var.project)}"
    company = "${lower(var.company)}"
  }
}

resource "null_resource" "template_kubernetes_security_group" {
  triggers {
    # uuid = "${uuid()}" # for debug
    output = "${data.template_file.kubernetes_security_group.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT

    echo '${data.template_file.kubernetes_security_group.rendered}' > ${local.path_module_kubernetes}/generated.security-group.tf
EOT
  }
}

data "template_file" "kubernetes_iam_role" {
  template = "${file("${path.module}/template.kube-iam-role.sh")}"

  vars {
    project = "${lower(var.project)}"
    company = "${lower(var.company)}"
    kops_cluster_name = "${var.kops_cluster_name}"
  }
}

resource "null_resource" "template_kubernetes_iam_role" {
  triggers {
    # uuid = "${uuid()}" # for debug
    output = "${data.template_file.kubernetes_iam_role.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${data.template_file.kubernetes_iam_role.rendered}' > ${local.path_module_kubernetes}/generated.iam-role.tf
EOT
  }
}

data "template_file" "correct_kubectl_cluster" {
  template = "${file("${path.module}/template.correct-kubectl-context.sh")}"

  vars {
    project = "${lower(var.project)}"
    company = "${lower(var.company)}"
    region = "${var.region}"
    kops_cluster_name = "${var.kops_cluster_name}"
  }
}

resource "null_resource" "correct_kubectl_cluster" {
  triggers {
    # uuid = "${uuid()}" # for debug
    output = "${data.template_file.correct_kubectl_cluster.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${data.template_file.correct_kubectl_cluster.rendered}' > ${local.path_module_kubernetes}/generated.correct-kubectl-context.sh
    chmod +x ${local.path_module_kubernetes}/generated.correct-kubectl-context.sh
EOT
  }
}

