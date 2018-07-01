resource "aws_ecs_cluster" "container" {
  name = "${local.cluster_name}"
}