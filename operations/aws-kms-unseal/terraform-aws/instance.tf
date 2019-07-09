resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 10

  tags = {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = "true"
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vault" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  count         = 1
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "vault-kms-unseal-${random_pet.env.id}"

  security_groups = [
    aws_security_group.vault.id,
  ]

  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = aws_iam_instance_profile.vault-kms-unseal.id

  tags = {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }

  user_data = data.template_file.vault.rendered
}

data "template_file" "vault" {
  template = file("userdata.tpl")

  vars = {
    kms_key    = aws_kms_key.vault.id
    vault_url  = var.vault_url
    aws_region = var.aws_region
  }
}

data "template_file" "format_ssh" {
  template = "connect to host with following command: ssh ubuntu@$${admin} -i private.key"

  vars = {
    admin = aws_instance.vault[0].public_ip
  }
}

output "connections" {
  value = <<VAULT
Connect to Vault via SSH   ssh ubuntu@${aws_instance.vault[0].public_ip} -i private.key
Vault web interface  http://${aws_instance.vault[0].public_ip}:8200/ui
VAULT

}

resource "aws_security_group" "vault" {
  name = "vault-kms-unseal-${random_pet.env.id}"
  description = "vault access"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "vault-kms-unseal-${random_pet.env.id}"
  }

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault Client Traffic
  ingress {
    from_port = 8200
    to_port = 8200
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
