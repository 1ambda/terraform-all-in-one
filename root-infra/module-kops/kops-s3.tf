resource "aws_s3_bucket" "infra_kops-secret" {
  bucket = "io.${lower(var.company)}.${lower(var.project)}.infra.kops-secret"
  acl = "private"

  force_destroy = true

  versioning {
    enabled = false
  }

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "io.${lower(var.company)}.${lower(var.project)}.infra.kops-secret"
  }
}
