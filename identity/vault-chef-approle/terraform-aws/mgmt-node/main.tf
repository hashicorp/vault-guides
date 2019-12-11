//--------------------------------------------------------------------
// Providers

provider "aws" {
  region = var.aws_region
}

//--------------------------------------------------------------------
// Resources

resource "aws_instance" "vault" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.vault.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault.id

  tags = {
    Name = "${var.environment_name}-vault-server"
  }

  provisioner "remote-exec" {
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ec2_pem)
    }

    inline = [
      "mkdir /home/ubuntu/vault-chef-approle-demo",
      "chown -R ubuntu:ubuntu /home/ubuntu/vault-chef-approle-demo",
    ]
  }

  provisioner "file" {
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ec2_pem)
    }

    source      = "../../chef"
    destination = "/home/ubuntu/vault-chef-approle-demo"
  }

  provisioner "file" {
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ec2_pem)
    }

    source      = "../../scripts"
    destination = "/home/ubuntu/vault-chef-approle-demo"
  }

  user_data = data.template_file.vault.rendered
}

resource "aws_security_group" "vault" {
  name        = "${var.environment_name}-vault-sg"
  description = "Access to Vault server"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.environment_name
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault Client Traffic
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Chef Server (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Chef Server (HTTPS)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "vault" {
  name               = "${var.environment_name}-vault-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault" {
  name   = "${var.environment_name}-vault-role-policy"
  role   = aws_iam_role.vault.id
  policy = data.aws_iam_policy_document.vault.json
}

resource "aws_iam_instance_profile" "vault" {
  name = "${var.environment_name}-vault-instance-profile"
  role = aws_iam_role.vault.name
}

//--------------------------------------------------------------------
// Data Sources

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

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

data "aws_iam_policy_document" "vault" {
  statement {
    sid    = "S3GetObject"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
  }
}

data "template_file" "vault" {
  template = file("${path.module}/templates/userdata-mgmt-node.tpl")

  vars = {
    tpl_aws_region              = var.aws_region
    tpl_s3_bucket_name          = var.s3_bucket_name
    tpl_vault_zip_url           = var.vault_zip_url
    tpl_chef_server_package_url = var.chef_server_package_url
    tpl_chef_dk_package_url     = var.chef_dk_package_url
    tpl_chef_admin              = var.chef_admin
    tpl_chef_admin_password     = var.chef_admin_password
    tpl_chef_org                = var.chef_org
    tpl_chef_app_name           = var.chef_app_name
  }
}

