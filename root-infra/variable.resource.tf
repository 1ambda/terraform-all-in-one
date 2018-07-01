## ECS

locals {
  ecs_instance_type = "t2.large"
  ecs_host_root_disk_size = "120"
  ecs_container_total_disk_size = "300"
  ecs_container_per_disk_size = "15"
}

## Storage

locals {
  zookeeper_clustering = true
  zookeeper_instance_type = "t2.medium"

  ec_clustering = false
  ec_instance_type = "cache.m3.medium"

  es_clustering = false
  es_node_instance_type = "t2.small.elasticsearch"
  es_node_disk_size = 35
  es_master_instance_type = "t2.small.elasticsearch"

  rds_clustering = false
  rds_instance_type = "db.t2.medium"
  rds_disk_size = 50
}

# Kubernetes

locals {
  kube_master_instance_count = 1
  kube_master_instance_type = "m4.large"
  kube_master_root_volume_size = 160
  kube_worker_instance_count = 2
  kube_worker_instance_type = "r4.large"
  kube_worker_root_volume_size = 128
  kops_ami = "kope.io/k8s-1.9-debian-jessie-amd64-hvm-ebs-2018-03-11"
  kube_version = "1.9.6"
}

