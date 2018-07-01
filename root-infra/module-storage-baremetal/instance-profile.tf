variable "ec2_instance_purpose" {
  default = "Storage"
}

resource "aws_iam_role" "storage_baremetal" {
  name = "${var.company}-${var.project}-EC2_${var.ec2_instance_purpose}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

variable "iam_policy_ec2_cloudwatch_arn" {}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_custom_metric" {
  role = "${aws_iam_role.storage_baremetal.name}"
  policy_arn = "${var.iam_policy_ec2_cloudwatch_arn}"
}

resource "aws_iam_instance_profile" "storage_baremetal" {
  name = "${var.company}-${var.project}-EC2_${var.ec2_instance_purpose}"
  role = "${aws_iam_role.storage_baremetal.name}"
}

