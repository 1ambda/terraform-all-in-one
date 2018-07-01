variable "helm_nginx_ingress_chart_version" {
  # https://hub.kubeapps.com/charts/stable/nginx-ingress
  default = "0.20.3"
}

variable "helm_nginx_ingress_controller_version" {
  # https://github.com/kubernetes/ingress-nginx/releases
  default = "0.15.0"
}

variable "helm_nginx_ingress_chart_name" {
  default = "global-entry"
}

locals {
  helm_nginx_ingress_elb_tag = "ingress.kops.${lower(var.project)}.${lower(var.company)}.io"
  # replace `, or .` to `\, \.`
  merged_whitelist_targets = "${replace(replace(join(",", var.whitelist_targets), ",", "\\,"), ".", "\\.")}"
  white_list_targets = "${var.whitelist_enabled == "true" ? local.merged_whitelist_targets : "0.0.0.0/0"}"
}

data "template_file" "install_nginx_ingress_chart_sh" {
  template = <<EOF
#!/bin/bash
count=$(helm ls | grep global-entry | wc -l | tr -s " ")

if [[ count -ge 1 ]]; then
  helm upgrade \
      --set controller.image.tag="${var.helm_nginx_ingress_controller_version}" \
      --set controller.service.annotations.domainName=${var.domain_name} \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"=${var.external_acm_use ? var.external_acm_arn : var.local_acm_arm } \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-additional-resource-tags"="Name=${local.helm_nginx_ingress_elb_tag}" \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/load-balancer-source-ranges"="${local.white_list_targets}" \
      --version ${var.helm_nginx_ingress_chart_version} \
      -f addon-ingress/chart.values.yaml \
      ${var.helm_nginx_ingress_chart_name} \
      stable/nginx-ingress

  sleep 15;
  kubectl get service --namespace default ${var.helm_nginx_ingress_chart_name}-nginx-ingress-controller -o json | jq -r '.status.loadBalancer.ingress[0].hostname'

else
  helm install stable/nginx-ingress \
      --set controller.image.tag="${var.helm_nginx_ingress_controller_version}" \
      --set controller.service.annotations.domainName=${var.domain_name} \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"=${var.external_acm_use ? var.external_acm_arn : var.local_acm_arm} \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-additional-resource-tags"="Name=${local.helm_nginx_ingress_elb_tag}" \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/load-balancer-source-ranges"="${local.white_list_targets}" \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-additional-resource-tags"="Name=internal-elb-ingress-nginx" \
      --version ${var.helm_nginx_ingress_chart_version} \
      --name ${var.helm_nginx_ingress_chart_name} \
      -f addon-ingress/chart.values.yaml

  sleep 15;
  kubectl get service --namespace default ${var.helm_nginx_ingress_chart_name}-nginx-ingress-controller -o json | jq -r '.status.loadBalancer.ingress[0].hostname'
fi
EOF
}

data "template_file" "delete_nginx_ingress_chart_sh" {
  template = <<EOF
#!/bin/bash
helm ls
helm delete global-entry; helm del --purge global-entry;
EOF
}

resource "null_resource" "delete_nginx_nigress" {
  triggers {
    # uuid = "${uuid()}" # for debug
    outout = "${data.template_file.install_nginx_ingress_chart_sh.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${data.template_file.delete_nginx_ingress_chart_sh.rendered}' > ${path.module}/addon-ingress/generated.delete-chart.sh
    chmod +x ${path.module}/addon-ingress/generated.delete-chart.sh
EOT
  }
}

resource "null_resource" "nginx_ingress_helm_value" {
  triggers {
    # uuid = "${uuid()}" # for debug

    outout = "${data.template_file.install_nginx_ingress_chart_sh.rendered}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '${data.template_file.install_nginx_ingress_chart_sh.rendered}' > ${path.module}/addon-ingress/generated.install-chart.sh
    chmod +x ${path.module}/addon-ingress/generated.install-chart.sh
EOT
  }
}
