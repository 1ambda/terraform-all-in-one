
locals {
  ansible_sshcfg_zookeeper = "${path.root}/../script-provision/ssh.zookeeper.cfg"
  ansible_inventory_zookeeper = "${path.root}/../script-provision/inventory.zookeeper.ansible"
  ansible_playbook_zookeeper = "${path.root}/../script-provision/generated.playbook-zookeeper.yml"
  provision_script_zookeeper = "${path.root}/../script-provision/generated.provision-zookeeper.sh"
  ssh_script_proxy_zookeeper_prefix = "${path.root}/../script-ssh/generated.ssh-proxy-zookeeper"
}

variable "zookeeper_version" {
  default = "3.4.12"
}

locals {
  download_url_zookeeper = "https://archive.apache.org/dist/zookeeper/zookeeper-${var.zookeeper_version}/zookeeper-${var.zookeeper_version}.tar.gz"
}

variable "bastion_user" {
  default = "ec2-user"
  # amazon linux ami
}

variable "bastion_public_ip" {}

data "template_file" "ssh_cfg_bastion" {
  template = "${file("${path.module}/provision/template.ssh-bastion.cfg")}"

  vars {
    bastion_user = "${var.bastion_user}"
    bastion_host = "${var.bastion_public_ip}"
    private_key_path = "${var.ssh_private_key_path}"
  }
}

data "template_file" "ssh_cfg_zookeeper" {
  template = "${file("${path.module}/provision/template.ssh-storage.cfg")}"

  vars {
    private_key_path = "${var.ssh_private_key_path}"
    bastion_host = "${var.bastion_public_ip}"
    bastion_user = "${var.bastion_user}"
    storage_user = "${var.zookeeper_user}"
  }
}

data "template_file" "template_playbook_zookeeper" {
  template = "${file("${path.module}/provision/template.playbook-zookeeper.yml")}"

  vars {
    storage_user = "${var.zookeeper_user}"
    download_url_zookeeper = "${local.download_url_zookeeper}"
    zookeeper_version = "${var.zookeeper_version}"
  }
}

data "template_file" "inventory_zookeeper" {
  template = <<EOF
[zookeeper_instances]
${join("\n", aws_instance.zookeeper.*.private_ip)}
EOF

  vars {
  }
}

resource "null_resource" "template_ansible" {
  triggers {
    # uuid = "${uuid()}" # for debug
    ssh_cfg_zookeeper = "${data.template_file.ssh_cfg_bastion.rendered}"
    ssh_cfg_bastion = "${data.template_file.ssh_cfg_bastion.rendered}"
    playbook_zookeeper = "${data.template_file.template_playbook_zookeeper.rendered}"
    inventory_zookeeper = "${data.template_file.inventory_zookeeper.rendered}"
  }

  depends_on = [
    "aws_instance.zookeeper",
  ]

  provisioner "local-exec" {
    command = <<EOT
    # ZOOKEEPER
    echo '${data.template_file.ssh_cfg_zookeeper.rendered}' > ${local.ansible_sshcfg_zookeeper}
    echo '${data.template_file.ssh_cfg_bastion.rendered}' >> ${local.ansible_sshcfg_zookeeper}
    echo '${data.template_file.inventory_zookeeper.rendered}' > ${local.ansible_inventory_zookeeper}
    echo '${data.template_file.template_playbook_zookeeper.rendered}' > ${local.ansible_playbook_zookeeper}

    echo '#!/usr/bin/env bash' > ${local.provision_script_zookeeper}
    echo 'CURRENT_DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"' >> ${local.provision_script_zookeeper}
    echo 'eval "$(ssh-agent -s)"; ssh-add -K ${var.ssh_private_key_path}' >> ${local.provision_script_zookeeper}
    echo 'STORAGE="zookeeper" $${CURRENT_DIR}/provision.sh' >> ${local.provision_script_zookeeper}
    chmod +x ${local.provision_script_zookeeper}
EOT
  }
}

# templates for ssh proxy, connection sh files

data "template_file" "ssh_proxy_zookeeper" {
  template = "${file("${path.root}/../template/template.ssh-proxy.sh")}"
  count = "${aws_instance.zookeeper.count}"

  vars {
    bastion_host = "${var.bastion_public_ip}"
    bastion_user = "${var.bastion_user}"
    ssh_private_key_path = "${var.ssh_private_key_path}"
    storage_port = "${var.zookeeper_port}"
    storage_host = "${element(aws_instance.zookeeper.*.private_ip, count.index)}"
  }
}

resource "null_resource" "ssh_proxy" {
  count = "${aws_instance.zookeeper.count}"

  triggers {
    # uuid = "${uuid()}" # for debug
    bastion_host = "${var.bastion_public_ip}"
    bastion_user = "${var.bastion_user}"
    ssh_private_key_path = "${var.ssh_private_key_path}"
    storage_port = "${var.zookeeper_port}"
    storage_host = "${element(aws_instance.zookeeper.*.private_ip, count.index)}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${element(data.template_file.ssh_proxy_zookeeper.*.rendered, count.index)}' > ${local.ssh_script_proxy_zookeeper_prefix}-${format("%02d", count.index + 1)}.sh
    chmod +x ${local.ssh_script_proxy_zookeeper_prefix}-${format("%02d", count.index + 1)}.sh
EOT
  }
}


