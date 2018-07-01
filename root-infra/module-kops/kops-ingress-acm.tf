resource "aws_acm_certificate" "cert" {
  count = "${var.external_acm_use ? 0 : 1}"
  domain_name = "${var.domain_name}"
  validation_method = "${var.local_acm_validation_method}"
  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "ingress.kops.${lower(var.project)}.${lower(var.company)}.io"
  }
}

output "local_acm_arm" {
  value = "${element(coalescelist(aws_acm_certificate.cert.*.arn, list("none")) ,0)}"
}
