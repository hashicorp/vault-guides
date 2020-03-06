resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > ${var.env}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.env}.pem"
  }
}

resource "aws_key_pair" "aws" {
  key_name   = var.env
  public_key = tls_private_key.main.public_key_openssh
}

