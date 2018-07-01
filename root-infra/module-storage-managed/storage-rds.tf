variable "rds_username" {}
variable "rds_password" {}

variable "rds_clustering" {}
variable "rds_disk_size" {}
variable "rds_instance_type" {}
variable "rds_db_name" {
  default = "hub"
}
variable "rds_port" {
  default = 3306
}
output "rds_port" {
  value = "${var.rds_port}"
}
output "rds_dns" {
  value = "${aws_db_instance.rds_mariadb.endpoint}"
}
variable "rds_backup_window" {}
variable "rds_maintenance_window" {}

locals {
  rds_name = "rds.${lower(var.project)}.${lower(var.company)}.io"
  rds_instance_identifier = "${lower(var.company)}-${lower(var.project)}-mariadb"
}

resource "aws_db_option_group" "rds_mariadb" {
  name = "${local.rds_instance_identifier}"
  option_group_description = "${local.rds_name}"
  engine_name = "mariadb"
  major_engine_version = "10.2"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.rds_name}"
    Clustering = "${var.rds_clustering}"
  }
}

resource "aws_db_parameter_group" "rds_mariadb" {
  name = "${local.rds_instance_identifier}"
  family = "mariadb10.2"
  description = "${local.rds_name}"

  parameter {
    name = "collation_connection"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name = "character_set_database"
    value = "utf8"
  }

  parameter {
    name = "character_set_filesystem"
    value = "utf8"
  }

  parameter {
    name = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name = "general_log"
    value = "0"
  }

  parameter {
    name = "slow_query_log"
    value = "1"
  }

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.rds_name}"
    Clustering = "${var.rds_clustering}"
  }
}

resource "aws_db_subnet_group" "rds_mariadb" {
  name = "${local.rds_name}"
  subnet_ids = [
    "${var.private_subnet_ids}"]

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.rds_name}"
    Clustering = "${var.rds_clustering}"
  }
}

resource "aws_db_instance" "rds_mariadb" {
  storage_type = "gp2"
  engine = "mariadb"
  engine_version = "10.2.12"

  identifier = "${local.rds_instance_identifier}"
  parameter_group_name = "${aws_db_parameter_group.rds_mariadb.name}"
  option_group_name = "${aws_db_option_group.rds_mariadb.name}"

  publicly_accessible = false
  db_subnet_group_name = "${aws_db_subnet_group.rds_mariadb.name}"
  vpc_security_group_ids = [
    "${aws_security_group.storage-managed.id}"]
  multi_az = "${var.rds_clustering ? true : false }"

  instance_class = "${var.on_testing ? "db.t2.small" : var.rds_instance_type }"
  allocated_storage = "${var.on_testing ? 30 : var.rds_disk_size }"

  // doens't make a final snapshot for smoother deletion
  final_snapshot_identifier = "${local.rds_instance_identifier}"
  skip_final_snapshot = "${var.on_testing}"

  name = "${var.rds_db_name}"
  port = "${var.rds_port}"
  username = "${var.rds_username}"
  password = "${var.rds_password}"

  backup_retention_period = 2
  backup_window = "${var.rds_backup_window}"
  maintenance_window = "${var.rds_maintenance_window}"
  apply_immediately = true

  // publishing rds logs (audit, error, general, slowquery) into cloudwatch
  // - https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.MySQL.html
  enabled_cloudwatch_logs_exports = [
    // "audit",
    // "general",
    "error",
    "slowquery",
  ]

  lifecycle {
    ignore_changes = [
      "username",
      "password"]
  }

  depends_on = [
    "aws_cloudwatch_log_group.rds_audit",
    "aws_cloudwatch_log_group.rds_general",
    "aws_cloudwatch_log_group.rds_error",
    "aws_cloudwatch_log_group.rds_slowquery",
  ]

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.rds_name}"
    Clustering = "${var.rds_clustering}"
  }
}

# Cloudwatch Log Groups for RDS

resource "aws_cloudwatch_log_group" "rds_audit" {
  name              = "/aws/rds/instance/${local.rds_instance_identifier}/audit"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "rds_error" {
  name              = "/aws/rds/instance/${local.rds_instance_identifier}/error"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "rds_general" {
  name              = "/aws/rds/instance/${local.rds_instance_identifier}/general"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "rds_slowquery" {
  name              = "/aws/rds/instance/${local.rds_instance_identifier}/slowquery"
  retention_in_days = 14
}


