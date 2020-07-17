//--------------------------------------------------------------------
// Resources

# Vault Server IAM Config
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

# Remote Host
resource "aws_iam_instance_profile" "remote-host" {
  name = "${var.environment_name}-remote-host-instance-profile"
  role = aws_iam_role.remote-host.name
}

resource "aws_iam_role" "remote-host" {
  name               = "${var.environment_name}-remote-host-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "remote-host" {
  name   = "${var.environment_name}-remote-host-role-policy"
  role   = aws_iam_role.remote-host.id
  policy = data.aws_iam_policy_document.remote-host.json
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
    sid    = "1"
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
}

data "aws_iam_policy_document" "remote-host" {
  statement {
    sid    = "1"
    effect = "Allow"

    actions = ["ec2:DescribeInstances"]

    resources = ["*"]
  }
}
