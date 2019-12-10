output "endpoints" {
  value = <<EOF

  vault_1 (${aws_instance.vault-transit.public_ip})
    - Initialized and unsealed.
    - The root token creates a transit key that enables the other Vaults to auto-unseal.
    - Does not join the High-Availability (HA) cluster.

    Local: VAULT_ADDR=http://${aws_instance.vault-transit.public_ip}:8200 vault
    Web:   open http://${aws_instance.vault-transit.public_ip}:8200/ui/
    SSH:   ssh -l ubuntu ${aws_instance.vault-transit.public_ip} -i ${var.key_name}.pem

  vault_2 (${aws_instance.vault-server[0].public_ip})
    - Initialized and unsealed.
    - The root token and recovery key is stored in /tmp/key.json.
    - K/V-V2 secret engine enabled and secret stored.
    - Leader of HA cluster

    Local: VAULT_ADDR=http://${aws_instance.vault-server[0].public_ip}:8200 vault
    Web:   open http://${aws_instance.vault-server[0].public_ip}:8200/ui/
    SSH:   ssh -l ubuntu ${aws_instance.vault-server[0].public_ip} -i ${var.key_name}.pem

    Root Token:
        ssh -l ubuntu -i ${var.key_name}.pem ${aws_instance.vault-server[0].public_ip} 'cat /tmp/key.json | jq -r ".root_token"'
    Recovery Key:
        ssh -l ubuntu -i ${var.key_name}.pem ${aws_instance.vault-server[0].public_ip} 'cat /tmp/key.json | jq -r ".recovery_keys_b64[0]"'

  vault_3 (${aws_instance.vault-server[1].public_ip})
    - Started
    - You will join it to the HA cluster.

    Local: VAULT_ADDR=http://${aws_instance.vault-server[1].public_ip}:8200 vault
    Web:   open http://${aws_instance.vault-server[1].public_ip}:8200/ui/
    SSH:   ssh -l ubuntu ${aws_instance.vault-server[1].public_ip} -i ${var.key_name}.pem

  vault_4 (${aws_instance.vault-server[2].public_ip})
    - Started
    - You will join it to the HA cluster.

    Local: VAULT_ADDR=http://${aws_instance.vault-server[2].public_ip}:8200 vault
    Web:   open http://${aws_instance.vault-server[2].public_ip}:8200/ui/
    SSH:   ssh -l ubuntu ${aws_instance.vault-server[2].public_ip} -i ${var.key_name}.pem

EOF
}
