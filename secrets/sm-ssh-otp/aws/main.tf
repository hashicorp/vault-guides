provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

//--------------------------------------------------------------------
// Vault Server Instance

resource "aws_instance" "vault-server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vault_demo_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [ aws_security_group.testing.id ]
  associate_public_ip_address = true
  private_ip                  = var.vault_server_private_ip
  iam_instance_profile        = aws_iam_instance_profile.vault-server.id

  user_data = templatefile("${path.module}/templates/userdata-vault-server.tpl", {
    tpl_vault_node_name = "vault-server",
    tpl_vault_storage_path = "/vault/vault-server",
    tpl_vault_zip_file = var.vault_zip_file,
    tpl_remote_host_ip = var.remote_host_private_ip
    tpl_configure_vault_server = var.configure_vault_server
  })

  tags = {
    Name = "${var.environment_name}-vault-server"
  }

  lifecycle {
    ignore_changes = [ami, tags]
  }
}

//--------------------------------------------------------------------
// Remote host

resource "aws_instance" "remote-host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vault_demo_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [ aws_security_group.testing.id ]
  associate_public_ip_address = true
  private_ip                  = var.remote_host_private_ip
  iam_instance_profile        = aws_iam_instance_profile.remote-host.id

  user_data = templatefile("${path.module}/templates/userdata-remote-host.tpl", {
    tpl_vault_ssh_helper_version = var.vault_ssh_helper_version,
    tpl_vault_server_ip = var.vault_server_private_ip
    tpl_configure_remote_host = var.configure_remote_host
  })

  tags = {
    Name = "${var.environment_name}-vault-server"
  }

  lifecycle {
    ignore_changes = [ami, tags]
  }
}