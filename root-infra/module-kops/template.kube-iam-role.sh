resource "aws_iam_role_policy_attachment" "kube_master_cloudwatch_custom_metric" {
  role = "masters.${kops_cluster_name}"
  policy_arn = "$${var.iam_policy_ec2_cloudwatch_arn}"

  depends_on = ["aws_iam_role.masters-kops-${project}-${company}-k8s-local"]
}

resource "aws_iam_role_policy_attachment" "kube_worker_cloudwatch_custom_metric" {
  role = "nodes.${kops_cluster_name}"
  policy_arn = "$${var.iam_policy_ec2_cloudwatch_arn}"

  depends_on = ["aws_iam_role.nodes-kops-${project}-${company}-k8s-local"]
}
