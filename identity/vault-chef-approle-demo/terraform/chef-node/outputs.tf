output "chef-node-public-ip" {
  value = "${aws_instance.chef-node.public_ip}"
}

output "approle-role-id" {
  value = "${data.vault_generic_secret.approle.data}"
}
