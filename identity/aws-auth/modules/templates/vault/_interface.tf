variable "aws_account_id" {}

variable "aws_auth_iam_role" {
  default = "NoRole"
}

variable "vault_listening_port" {
  default = "8200"
}

variable "vault_instance_security_group_id" {}

# Allows traffic to Vault from any source
variable "allowed_vault_cidr_blocks" {
  default = "0.0.0.0/0"
}

/**output "vault_iam_role_name" {
  value = "vault_role" #"${aws_iam_role.vault_role.name}"
}

output "vault_iam_profile_name" {
  value = "${aws_iam_instance_profile.vault_profile.name}"
}*/

output "vault_user_data" {
  value = "${data.template_file.vault_init_config.rendered}"
}
