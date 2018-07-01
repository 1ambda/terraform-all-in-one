variable "ec_redis_version" {}
variable "ec_instance_type" {}
variable "ec_snapshot_window" {}
variable "ec_maintenance_window" {}
variable "ec_clustering" {}
variable "ec_port" {
 default = 6379
}
output "ec_port" {
  value = "${var.ec_port}"
}
output "ec_dns" {
  value = "${aws_elasticache_replication_group.redis.primary_endpoint_address}"
}

locals {
  redis_domain_name = "redis.${lower(var.project)}.${lower(var.company)}.io"
  redis_cluster_id = "${lower(var.company)}-${lower(var.project)}"
  redis_cluster_name = "${lower(var.company)}-${lower(var.project)}-redis"
}

resource "aws_elasticache_subnet_group" "redis" {
  name = "${local.redis_cluster_name}"
  description = "${local.redis_domain_name}"
  subnet_ids = [
    "${var.private_subnet_ids}"]
}

resource "aws_elasticache_replication_group" "redis" {
  engine = "redis"
  engine_version = "${var.ec_redis_version}"

  replication_group_id = "${local.redis_cluster_id}"
  replication_group_description = "${local.redis_domain_name}"
  node_type = "${var.on_testing ? "cache.t2.small" : var.ec_instance_type }"
  port = "${var.ec_port}"

  automatic_failover_enabled = "${var.ec_clustering ? true : false}"
  number_cache_clusters = "${var.ec_clustering ? length(var.availability_zones) : 1}"
  availability_zones = "${local.configured_azs["${var.ec_clustering ? "clustering" : "standalone"}"]}"

  subnet_group_name = "${aws_elasticache_subnet_group.redis.name}"
  security_group_ids = [
    "${aws_security_group.storage-managed.id}"]

  parameter_group_name = "${aws_elasticache_parameter_group.redis.name}"

  maintenance_window = "${var.ec_maintenance_window}"

  apply_immediately = true

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.redis_domain_name}"
    Clustering = "${var.ec_clustering}"
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  name = "${local.redis_cluster_id}"
  description = "${local.redis_domain_name}"
  family = "redis${replace(var.ec_redis_version, "/\\.[\\d]+$/","")}"
  parameter = []
}


