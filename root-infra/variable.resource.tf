
## ECS Setup

variable "ecs_instance_type" {
  default = "t2.large"
}
variable "ecs_host_root_disk_size" {
  default = "120"
}
variable "ecs_container_total_disk_size" {
  default = "300"
}
variable "ecs_container_per_disk_size" {
  default = "15"
}

## Clustering Setup

variable "zookeeper_clustering" {
  default = true
}
variable "zookeeper_instance_type" {
  default = "t2.medium"
}

variable "ec_clustering" {
  default = false
}
variable "ec_instance_type" {
  default = "cache.m3.medium"
}

variable "es_clustering" {
  default = false
}
variable "es_node_instance_type" {
  default = "t2.small.elasticsearch"
}
variable "es_node_disk_size" {
  default = 35
}
variable "es_master_instance_type" {
  default = "t2.small.elasticsearch"
}

variable "rds_clustering" {
  default = false
}
variable "rds_instance_type" {
  default = "db.t2.medium"
}
variable "rds_disk_size" {
  default = 50
}




