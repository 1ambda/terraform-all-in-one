variable "instance_purpose" {
  default = "Bastion"
}

resource "aws_iam_role" "bastion" {
  name = "${var.company}-${var.project}-EC2_${var.instance_purpose}"
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

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_custom_metric" {
  role = "${aws_iam_role.bastion.name}"
  policy_arn = "${var.iam_policy_ec2_cloudwatch_arn}"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.company}-${var.project}-EC2_${var.instance_purpose}"
  role = "${aws_iam_role.bastion.name}"
}


