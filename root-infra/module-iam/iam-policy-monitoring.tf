
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/mon-scripts.html
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html
resource "aws_iam_policy" "ec2_cloudwatch_custom_metric" {
  name = "${var.company}-${var.project}-EC2Cloudwatch_CustomMetric"
  path = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:DescribeTags",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

output "iam_policy_ec2_cloudwatch_arn" {
  value = "${aws_iam_policy.ec2_cloudwatch_custom_metric.arn}"
}

