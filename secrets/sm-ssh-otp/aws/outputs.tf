output "endpoints" {
  value = <<EOF

  NOTE: While Terraform's work is done, these instances need time to complete
        their own installation and configuration. Progress is reported within
        the log file `/var/log/tf-user-data.log` and reports 'Complete' when
        the instance is ready.

  vault-server (${aws_instance.vault-server.public_ip}) | internal: (${aws_instance.vault-server.private_ip})
    - Initialized and unsealed.
    - The root token and recovery key is stored in /tmp/key.json.

    $ ssh -l ubuntu ${aws_instance.vault-server.public_ip} -i ${var.key_name}.pem

  remote-host (${aws_instance.remote-host.public_ip}) | internal: (${aws_instance.remote-host.private_ip})

    $ ssh -l ubuntu ${aws_instance.remote-host.public_ip} -i ${var.key_name}.pem

EOF
}
