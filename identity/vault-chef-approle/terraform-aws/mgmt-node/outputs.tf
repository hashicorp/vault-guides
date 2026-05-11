# Copyright IBM Corp. 2017, 2026

output "vault-public-ip" {
  value = aws_instance.vault.public_ip
}

