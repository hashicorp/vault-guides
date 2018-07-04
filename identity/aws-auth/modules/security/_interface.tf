variable "name_prefix" {}

variable "ssh_port" {
  default = "22"
}

variable vault_listening_port {
  default = "8200"
}

# Allows ssh traffic from any source
variable "allowed_ssh_cidr_blocks" {
  default = "0.0.0.0/0"
}

# Security groups that are allowed to communicate with Vault
variable "allowed_ssh_security_group_ids" {
  default = [""]
}

variable "owner_tag" {}

variable "ttl_tag" {}

# This would allow updating rules amd to allow access based on this id
output "security_group_id" {
  value = "${aws_security_group.lc_security_group.id}"
}
