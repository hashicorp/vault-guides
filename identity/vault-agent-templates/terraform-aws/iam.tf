//--------------------------------------------------------------------
// Resources

## Vault Server IAM Config
resource "aws_iam_instance_profile" "vault-server" {
  name = "${var.environment_name}-vault-server-instance-profile"
  role = aws_iam_role.vault-server.name
}

resource "aws_iam_role" "vault-server" {
  name               = "${var.environment_name}-vault-server-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault-server" {
  name   = "${var.environment_name}-vault-server-role-policy"
  role   = aws_iam_role.vault-server.id
  policy = data.aws_iam_policy_document.vault-server.json
}

# Vault Client IAM Config
resource "aws_iam_instance_profile" "vault-client" {
  name = "${var.environment_name}-vault-client-instance-profile"
  role = aws_iam_role.vault-client.name
}

resource "aws_iam_role" "vault-client" {
  name               = "${var.environment_name}-vault-client-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault-client" {
  name   = "${var.environment_name}-vault-client-role-policy"
  role   = aws_iam_role.vault-client.id
  policy = data.aws_iam_policy_document.vault-client.json
}

//--------------------------------------------------------------------
// Data Sources

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-server" {
  statement {
    sid    = "ConsulAutoJoin"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }

  statement {
    sid    = "VaultAWSAuthMethod"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "vault-client" {
  statement {
    sid    = "ConsulAutoJoin"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }
}

