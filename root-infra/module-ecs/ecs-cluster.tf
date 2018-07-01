resource "aws_ecs_cluster" "interpreter" {
  name = "${local.cluster_name}"
}