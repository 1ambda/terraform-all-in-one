data "template_file" "ecs_userdata_install_cloudwatch_custom_metric_agent" {
  template = "${file("${path.root}/../template/template.install-cloudwatch-custom-metric-agent-ecs.sh")}"

  vars {
    user = "ec2-user"
    installer = "yum"
    agent_version = "1.0.0"
  }
}

data "template_file" "ecs_userdata_configure_options" {
  template = "${file("${path.root}/../template/template.ecs-configure-options.sh")}"

  vars {
    ecs_cluster_name = "${local.cluster_name}"
    ecs_task_cleanup_duration = "${var.ecs_task_cleanup_duration}"
    ecs_image_minimum_cleanup_age = "${var.ecs_image_minimum_cleanup_age}"
  }
}

data "template_file" "ecs_awslogs_template" {
  template = "${file("${path.root}/../template/template.ecs-awslogs-template.sh")}"

  vars {
    awslogs_stream_prefix = "${local.instance_name}"
  }
}

data "template_file" "ecs_awslogs_update_region" {
  template = "${file("${path.root}/../template/template.ecs-awslogs-update-region.sh")}"

  vars {
    awslogs_stream_prefix = "${local.instance_name}"
    region = "${var.region}"
  }
}

data "template_file" "ecs_awslogs_upstart" {
  template = "${file("${path.root}/../template/template.ecs-awslogs-upstart.sh")}"

  vars {
  }
}

data "template_file" "ecs_logrotate_docker_daemon" {
  template = "${file("${path.root}/../template/template.ecs-logrotate-docker-daemon.sh")}"

  vars {
  }
}

# cloud-init

data "template_cloudinit_config" "ecs_user_data" {
  gzip = false
  base64_encode = true

  # configure ecs specific options
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.ecs_userdata_configure_options.rendered}"
  }

  # set awslogs
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.ecs_awslogs_template.rendered}"
  }
  part {
    content_type = "text/upstart-job"
    content = "${data.template_file.ecs_awslogs_upstart.rendered}"
  }

  # set docker options
  part {
    content_type = "text/cloud-boothook;"
    content = <<EOF
cloud-init-per once docker_options echo 'OPTIONS="$${OPTIONS} --storage-opt dm.basesize=${var.ecs_container_per_disk_size}G"' >> /etc/sysconfig/docker
EOF
  }

  # update ecs agent and apply amazon linux patches
  part {
    content_type = "text/x-shellscript"
    content = <<EOF
#!/bin/bash
yum update -y
yum update -y ecs-init
restart ecs
EOF
  }

  # install agent for cloudwatch custom metric
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.ecs_userdata_install_cloudwatch_custom_metric_agent.rendered}"
  }

  # replace region in `/etc/awslogs/awscli.conf`
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.ecs_awslogs_update_region.rendered}"
  }

  # configure logrotate
  part {
    content_type = "text/x-shellscript"
    content = "${data.template_file.ecs_logrotate_docker_daemon.rendered}"
  }

  # block meta data access
  part {
    content_type = "text/x-shellscript"
    content = <<EOF
#!/bin/bash
iptables -A OUTPUT -m owner ! --uid-owner root -d 169.254.169.254 -j REJECT
EOF
  }
}
