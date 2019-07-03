output "endpoints" {
  value = <<EOF

Auto-unseal Provider IP (public):  ${aws_instance.vault-transit.public_ip}
Auto-unseal Provider IP (private): ${aws_instance.vault-transit.private_ip}

For example:
  ssh -i ${var.key_name}.pem ubuntu@${aws_instance.vault-transit.public_ip}


Server node IPs (public):  ${join(", ", aws_instance.vault-server.*.public_ip)}
Server node IPs (private): ${join(", ", aws_instance.vault-server.*.private_ip)}

For example:
   ssh -i ${var.key_name}.pem ubuntu@${aws_instance.vault-server[0].public_ip}
EOF
}
