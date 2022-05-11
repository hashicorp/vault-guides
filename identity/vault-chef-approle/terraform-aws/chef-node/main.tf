//--------------------------------------------------------------------
// Providers

provider "aws" {
  region = var.aws_region
}

# These should typically be set via environment variables:
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs#provider-arguments
provider "vault" {
  address = var.vault_address

  # Token used to get AppRole RoleID
  token = var.vault_token
}

# Reads the app-1 role from the approle auth method
data "vault_approle_auth_backend_role_id" "role" {
  backend   = "approle"
  role_name = "app-1"
}

//--------------------------------------------------------------------
// Resources

resource "aws_instance" "chef-node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.chef-node.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.environment_name}-chef-node"
  }

  user_data = data.template_file.role-id.rendered

  provisioner "chef" {
    connection {
      host        = coalesce(self.public_ip, self.private_ip)
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ec2_pem)
    }

    node_name = "chef-node-test"

    //client_options = ["log_level :debug"]
    server_url = var.chef_server_address
    user_name  = "demo-admin"
    user_key   = data.aws_s3_bucket_object.chef_bootstrap_pem.body

    client_options  = ["chef_license 'accept'"]
    run_list                = ["recipe[vault_chef_approle_demo]"]
    recreate_client         = true
    fetch_chef_certificates = true
    ssl_verify_mode         = ":verify_none"
    version                 = "16.17.18"
  }
}


resource "aws_security_group" "chef-node" {
  name        = "${var.environment_name}-chef-node-sg"
  description = "Access to Chef node"
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

//--------------------------------------------------------------------
// Data Sources

data "aws_s3_bucket_object" "chef_bootstrap_pem" {
  bucket = var.s3_bucket_name
  key    = "demo-admin-private-key.pem"
}

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


data "template_file" "role-id" {
  template = file("${path.module}/templates/userdata-chef-node.tpl")

  vars = {
    tpl_role_id    = "${data.vault_approle_auth_backend_role_id.role.role_id}"
    tpl_vault_addr = var.vault_address
  }
}
