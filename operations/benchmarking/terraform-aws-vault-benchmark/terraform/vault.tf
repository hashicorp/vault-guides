data "aws_ami" "vault" {
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.vault_ami]
  }

  owners = ["self"]
}

resource "aws_instance" "vault" {
  count                       = 3
  ami                         = data.aws_ami.vault.id
  instance_type               = var.vault_instance_type
  subnet_id                   = module.vpc.private_subnets[count.index]
  key_name                    = aws_key_pair.aws.key_name
  ebs_optimized               = "true"
  associate_public_ip_address = false
  private_ip                  = var.vault_ips[count.index]

  vpc_security_group_ids = [
    aws_security_group.vault.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.benchmark.id

  tags = {
    env   = var.env
    role  = "vault"
    owner = var.owner
    TTL   = var.ttl
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }

  /*
  root_block_device {
    volume_type = "io1"
    volume_size = "100"
    iops        = "3000"
  }
  */

  user_data = data.template_file.vault.rendered
}

data "template_file" "vault" {
  template = file("${path.module}/templates/vault.tpl")

  vars = {
    env    = var.env
    kms_id = aws_kms_key.vault.key_id
    cert   = tls_locally_signed_cert.vault.cert_pem
    key    = tls_private_key.vault.private_key_pem
    ca     = tls_self_signed_cert.root.cert_pem
    region = var.region
  }
}

