//--------------------------------------------------------------------
// Vault Client Instance

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
    tpl_vault_zip_file          = var.vault_zip_file
    tpl_vault_server_addr  = aws_instance.vault-server[0].private_ip
  }
}
