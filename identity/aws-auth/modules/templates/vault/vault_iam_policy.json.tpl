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
      },
      {
        "Effect": "Allow",
        "Action": ["sts:AssumeRole"],
        "Resource": [
          "arn:aws:iam::${aws_account_id}:role/${vault_iam_role}"
        ]
      }
    ]
  }