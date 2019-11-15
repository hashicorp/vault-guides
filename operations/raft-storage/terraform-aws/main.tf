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
// Master Key Encryption Provider instance
//    This node does not participate in the HA clustering

resource "aws_instance" "vault-transit" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vault_demo_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = ["${aws_security_group.testing.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault-transit.id

  user_data = data.template_file.vault-transit.rendered

  tags = {
    Name = "${var.environment_name}-vault-transit"
  }

  lifecycle {
    ignore_changes = [
      ami,
      tags,
    ]
  }
}

data "template_file" "vault-transit" {
  template = file("${path.module}/templates/userdata-vault-transit.tpl")

  vars = {
    tpl_vault_zip_file     = "${var.vault_zip_file}"
    tpl_vault_service_name = "vault-${var.environment_name}"
  }
}


//--------------------------------------------------------------------
// Vault Server Instance

resource "aws_instance" "vault-server" {
  count                       = var.vault_server_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vault_demo_vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = ["${aws_security_group.testing.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vault-server.id

  user_data = data.template_file.vault-server.rendered
  #user_data = "${data.template_file.vault-server[count.index]}"

  tags = {
    Name = "${var.environment_name}-vault-server-${count.index}"
  }

  lifecycle {
    ignore_changes = [ami, tags]
  }
}

data "template_file" "vault-server" {
  template = file("${path.module}/templates/userdata-vault-server.tpl")

  vars = {
    tpl_vault_zip_file     = "${var.vault_zip_file}"
    tpl_vault_service_name = "vault-${var.environment_name}"
    tpl_vault_transit_addr  = "${aws_instance.vault-transit.private_ip}"
  }
}
