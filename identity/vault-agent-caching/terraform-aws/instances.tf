#--------------------------------------------------------------------
# Vault Server Instance
#--------------------------------------------------------------------
resource "aws_instance" "vault-server" {
  count                       = var.vault_server_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vault_demo_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.testing.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault-server.id

  tags = {
    Name     = "${var.environment_name}-vault-server-${count.index}"
    ConsulDC = var.consul_dc
    TTL      = var.hashibot_reaper_ttl
  }

  user_data = data.template_file.vault-server.rendered

  lifecycle {
    ignore_changes = [
      ami,
      tags,
    ]
  }
}

resource "aws_iam_user" "vault_demo_user" {
  name = "vault_demo_user"
}

resource "aws_iam_access_key" "vault_demo_user_key" {
  user = aws_iam_user.vault_demo_user.name
}

resource "aws_iam_user_policy" "vault_demo_user_policy" {
  user = aws_iam_user.vault_demo_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": "iam:*",
          "Resource": "*"
      }
  ]
}
  
EOF

}

data "aws_caller_identity" "current" {
}

data "template_file" "vault-server" {
  template = file("${path.module}/templates/userdata-vault-server.tpl")

  vars = {
    tpl_vault_zip_file          = var.vault_zip_file
    tpl_consul_zip_file         = var.consul_zip_file
    tpl_consul_dc               = var.consul_dc
    tpl_vault_service_name      = "vault-${var.environment_name}"
    tpl_kms_key                 = aws_kms_key.vault.id
    tpl_aws_region              = var.aws_region
    tpl_consul_bootstrap_expect = var.vault_server_count
    aws_access_key_id           = aws_iam_access_key.vault_demo_user_key.id
    aws_secret_access_key       = aws_iam_access_key.vault_demo_user_key.secret
    account_id                  = data.aws_caller_identity.current.account_id
    role_name                   = "${var.environment_name}-vault-client-role"
  }
}

#--------------------------------------------------------------------
# Vault Client Instance
#--------------------------------------------------------------------
resource "aws_instance" "vault-client" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vault_demo_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.testing.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault-client.id

  tags = {
    Name     = "${var.environment_name}-vault-client"
    ConsulDC = "consul-${var.aws_region}"
    TTL      = var.hashibot_reaper_ttl
  }

  user_data = data.template_file.vault-client.rendered

  lifecycle {
    ignore_changes = [
      ami,
      tags,
    ]
  }
}

data "template_file" "vault-client" {
  template = file("${path.module}/templates/userdata-vault-client.tpl")

  vars = {
    tpl_vault_zip_file     = var.vault_zip_file
    tpl_consul_zip_file    = var.consul_zip_file
    tpl_consul_dc          = var.consul_dc
    tpl_vault_service_name = "vault-${var.environment_name}"
    tpl_vault_server_addr  = aws_instance.vault-server[0].private_ip
  }
}

