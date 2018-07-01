terraform {
  required_version = ">= 0.11.7"

//  backend "s3" {
//    bucket     = "io.${var.company}.${var.project}.infra.terraform"
//    key        = "root-infra/tfstate"
//    region     = "${var.region}" # (Seoul)
//    encrypt    = true
//    dynamodb_table = "io.${lower(var.company)}.${lower(var.project)}.infra.terraform"
//  }
}

resource "aws_dynamodb_table" "infra_terraform-lock" {
  name = "io.${lower(var.company)}.${lower(var.project)}.infra.terraform"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "io.${lower(var.company)}.${lower(var.project)}.infra.terraform"
  }
}

resource "aws_s3_bucket" "infra_terraform" {
  bucket = "io.${lower(var.company)}.${lower(var.project)}.infra.terraform"
  acl = "private"

  versioning {
    enabled = false
  }

  force_destroy = "${var.on_testing}"

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "io.${lower(var.company)}.${lower(var.project)}.infra.terraform"
  }
}
