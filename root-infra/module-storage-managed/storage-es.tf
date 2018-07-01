variable "es_clustering" {}
variable "es_node_instance_type" {}
variable "es_node_disk_size" {}
variable "es_master_instance_type" {}
variable "es_version" {}
variable "es_snapshot_window_start_hour_utc" {}
variable "es_http_port" {
  default = "80"
}
variable "es_port" {
  default = "9200"
}

output "es_http_port" {
  value = "${var.es_http_port}"
}
output "es_port" {
  value = "${var.es_port}"
}
output "es_dns" {
  value = "${aws_elasticsearch_domain.search_cluster.endpoint}"
}

locals {
  es_domain_name = "search.${lower(var.project)}.${lower(var.company)}.io"
  es_domain_alias = "${lower(var.company)}-${lower(var.project)}"
  es_cw_log_group_slow_index = "/search.${lower(var.project)}.${lower(var.company)}.io/slow_index"
  es_cw_log_group_slow_search = "/search.${lower(var.project)}.${lower(var.company)}.io/slow_search"
}

resource "aws_elasticsearch_domain" "search_cluster" {
  domain_name = "${local.es_domain_alias}"
  elasticsearch_version = "${var.es_version}"

  depends_on = [
    "aws_cloudwatch_log_group.es_publish_slow_log_index",
    "aws_cloudwatch_log_group.es_publish_slow_log_search",
  ]

  cluster_config {
    instance_type = "${var.on_testing ? "t2.small.elasticsearch" : var.es_node_instance_type }"
    instance_count = "${var.es_clustering ? 2 : 1 }"
    dedicated_master_enabled = "${var.es_clustering ? true : false }"
    dedicated_master_type = "${var.es_clustering ? var.es_master_instance_type : "" }"
    dedicated_master_count = "${var.es_clustering ? 3 : 0 }"
    # https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-zoneawareness
    zone_awareness_enabled = "${var.es_clustering ? true : false }"
  }

  vpc_options {
    security_group_ids = [
      "${aws_security_group.storage-managed.id}"]
    subnet_ids = [
      "${local.configured_subnets["${var.es_clustering ? "clustering" : "standalone"}"]}"]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    # http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-limits.html
    volume_size = "${var.on_testing? 35 : var.es_node_disk_size }"
  }

  snapshot_options {
    automated_snapshot_start_hour = "${var.es_snapshot_window_start_hour_utc}"
  }

  log_publishing_options {
    log_type = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.es_publish_slow_log_index.arn}"
    enabled = true
  }

  log_publishing_options {
    log_type = "SEARCH_SLOW_LOGS"
    cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.es_publish_slow_log_search.arn}"
    enabled = true
  }

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.es_domain_name}"
    Clustering = "${var.es_clustering}"
  }
}

resource "aws_elasticsearch_domain_policy" "search_cluster" {
  domain_name = "${aws_elasticsearch_domain.search_cluster.domain_name}"

  # handles access in the es security group
  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Principal": {
              "AWS": [
                "*"
              ]
            },
            "Action": [
              "es:*"
            ],
            "Effect": "Allow",
            "Resource": "${aws_elasticsearch_domain.search_cluster.arn}/*"
        }
    ]
}
POLICIES
}

# publishing es slow log into cloudwatch

resource "aws_cloudwatch_log_group" "es_publish_slow_log_index" {
  name = "${local.es_cw_log_group_slow_index}"
  retention_in_days = 7

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.es_domain_name}"
  }
}

resource "aws_cloudwatch_log_group" "es_publish_slow_log_search" {
  name = "${local.es_cw_log_group_slow_search}"
  retention_in_days = 7

  tags {
    Terraform = "true"

    Environment = "${var.environment}"
    Company = "${var.company}"
    Project = "${var.project}"

    Name = "${local.es_domain_name}"
  }
}

resource "aws_cloudwatch_log_resource_policy" "es_slow_logs" {
  policy_name = "${var.company}-${var.project}-ES_SlowLogs"
  policy_document = <<CONFIG
    {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {
                "Service": "es.amazonaws.com"
            },
            "Action": [
                "logs:PutLogEvents",
                "logs:PutLogEventsBatch",
                "logs:CreateLogStream"
            ],
            "Resource": [
                "${aws_cloudwatch_log_group.es_publish_slow_log_search.arn}",
                "${aws_cloudwatch_log_group.es_publish_slow_log_index.arn}"
            ]
        }]
    }
CONFIG
}
