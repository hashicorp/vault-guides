output "chef-node-public-ip" {
  value = aws_instance.chef-node.public_ip
}

output "approle-role-id" {
  value = "${data.vault_approle_auth_backend_role_id.role.role_id}"
}
