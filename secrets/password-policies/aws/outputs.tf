output "endpoints" {
  value = <<EOF

  NOTE: While Terraform's work is done, the Vault server needs time to complete
        its own installation and configuration. Progress is reported within
        the log file `/var/log/tf-user-data.log` and reports 'Complete' when
        the instance is ready.

  vault-server (${aws_instance.vault-server.public_ip})
    - Initialized and unsealed.
    - The root token is stored in /home/ubuntu/root_key
    - The unseal key is stored in /home/ubuntu/unseal_keys

    $ ssh -l ubuntu ${aws_instance.vault-server.public_ip} -i ${var.key_name}.pem

EOF
}
