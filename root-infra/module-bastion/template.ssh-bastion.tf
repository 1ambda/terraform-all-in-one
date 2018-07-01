variable "bastion_user" {
  default = "ec2-user" # Amazon Linux AMI
}

locals {
  ssh_script_path = "${path.root}/../script-ssh/generated.ssh-bastion.sh"
}

data "template_file" "ssh-bastion" {
  template = "${file("${path.root}/../template/template.ssh-bastion.sh")}"

  vars {
    bastion_host = "${aws_instance.bastion.public_ip}"
    bastion_user = "${var.bastion_user}"
    ssh_private_key_path = "${var.ssh_private_key_path}"
    kops_cluster_name = "${var.kops_cluster_name}"

    region = "${var.region}"
    project = "${lower(var.project)}"
    company = "${lower(var.company)}"
  }
}

resource "null_resource" "template-ssh-bastion" {
  triggers {
    # uuid = "${uuid()}" # for debug
    output = "${data.template_file.ssh-bastion.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${data.template_file.ssh-bastion.rendered}' > ${local.ssh_script_path}
    chmod +x ${local.ssh_script_path}
EOT
  }
}
