data "template_file" "bastion_userdata_install_storage_clients" {
  template = "${file("${path.root}/../template/template.install-storage-clients.sh")}"

  vars {
    user = "ec2-user"
    installer = "yum"
  }
}

data "template_file" "bastion_userdata_install_cloudwatch_custom_metric_agent" {
  template = "${file("${path.root}/../template/template.install-cloudwatch-custom-metric-agent-ec2.sh")}"

  vars {
    user = "ec2-user"
    installer = "yum"
    agent_version = "1.2.2"
  }
}

data "aws_ami" "ec2_amazon_linux" {
  most_recent = true

  # ref:  https://aws.amazon.com/amazon-linux-ami/
  filter {
    name = "name"
    values = [
      "amzn-ami-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon"]
  }
}

data "template_cloudinit_config" "bastion_user_data" {
  gzip = false
  base64_encode = true

  # install patches for Amazon Linux
  part {
    content_type = "text/x-shellscript"
    content = <<EOF
#!/bin/bash
yum update -y
EOF
  }

  # install mysql, redis client
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.bastion_userdata_install_storage_clients.rendered}"
  }

  # install agent for cloudwatch custom metric
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.bastion_userdata_install_cloudwatch_custom_metric_agent.rendered}"
  }
}

