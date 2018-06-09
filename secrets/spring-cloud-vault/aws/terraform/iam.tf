resource "aws_iam_user" "vault" {
  name = "${var.env}"
}

resource "aws_iam_access_key" "vault" {
  user = "${aws_iam_user.vault.name}"
}

resource "aws_iam_user_policy" "vault_ro" {
  name = "${var.env}"
  user = "${aws_iam_user.vault.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "iam:GetInstanceProfile",
        "iam:GetUser",
        "iam:GetRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "springboot" {
  name = "${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "springboot" {
  name = "${var.env}"
  role = "${aws_iam_role.springboot.name}"
}
