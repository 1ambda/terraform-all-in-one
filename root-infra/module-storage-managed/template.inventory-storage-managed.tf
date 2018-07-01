locals {
  managed_storage_inventory_file = "${path.root}/../script-ssh/inventory.storage-managed"
}

resource "null_resource" "inventory-storage-managed" {
  triggers {
    # uuid = "${uuid()}" # for debug
    managed_stroage_dns = "${join(",", list(aws_db_instance.rds_mariadb.endpoint, aws_elasticsearch_domain.search_cluster.endpoint, aws_elasticache_replication_group.redis.primary_endpoint_address))}"
    managed_storage_ports = "${join(",", list(var.rds_port, var.es_port, var.es_http_port, var.ec_port))}"
  }

  provisioner "local-exec" {
    command = <<EOT
    echo '\t(storage-baremetal)' > ${local.managed_storage_inventory_file}
    echo 'rds-maridadb\t${aws_db_instance.rds_mariadb.endpoint}' >> ${local.managed_storage_inventory_file}
    echo 'elasticsearch\t${aws_elasticsearch_domain.search_cluster.endpoint}:${var.es_port} (HTTP :${var.es_http_port})' >> ${local.managed_storage_inventory_file}
    echo 'elasticache\t\t${aws_elasticache_replication_group.redis.primary_endpoint_address}:${var.ec_port}' >> ${local.managed_storage_inventory_file}
EOT
  }

  depends_on = [
    "aws_elasticache_replication_group.redis",
    "aws_elasticsearch_domain.search_cluster",
    "aws_db_instance.rds_mariadb",
  ]
}

