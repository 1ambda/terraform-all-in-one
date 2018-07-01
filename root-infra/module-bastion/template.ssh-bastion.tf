variable "bastion_user" {
  default = "ec2-user" # Amazon Linux AMI
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
    echo '${data.template_file.ssh-bastion.rendered}' > ${path.root}/../script/generated.ssh-bastion.sh
    chmod +x ${path.root}/../script/generated.ssh-bastion.sh
EOT
  }
}
