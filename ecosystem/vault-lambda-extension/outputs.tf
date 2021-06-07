output "info" {
  value = <<EOF

Postgres database address
    ${aws_db_instance.main.address}

Elastic Container Registry (ECR) repository address
    ${aws_ecr_repository.demo-function.repository_url}

Vault Server IP (public)
    ${aws_instance.vault-server.public_ip}

Vault UI URL
    http://${aws_instance.vault-server.public_ip}:8200/ui

You can SSH into the Vault EC2 instance using private.key:
    ssh -i private.key ubuntu@${aws_instance.vault-server.public_ip}

EOF
}

