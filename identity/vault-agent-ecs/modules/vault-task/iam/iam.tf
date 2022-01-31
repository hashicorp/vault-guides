resource "aws_iam_policy" "vault_agent" {
  name        = "${var.name}-vault-agent"
  path        = "/ecs/"
  description = "Policy for AWS IAM Auth Method for Vault"
  tags        = local.tags

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
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_task" {
  name        = "${var.name}-ecs-task"
  path        = "/ecs/"
  description = "Policy for ECS task"
  tags        = local.tags

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "efs_access_point" {
  name        = "${var.name}-efs-access-point"
  path        = "/ecs/"
  description = "Policy for task IAM role to access to EFS access point"
  tags        = local.tags

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Resource": "${var.ecs_task_efs_access_point_arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "task" {
  name = var.name
  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "vault_agent" {
  role       = aws_iam_role.task.id
  policy_arn = aws_iam_policy.vault_agent.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.task.id
  policy_arn = aws_iam_policy.ecs_task.arn
}

resource "aws_iam_role_policy_attachment" "efs_access_point" {
  role       = aws_iam_role.task.id
  policy_arn = aws_iam_policy.efs_access_point.arn
}