variable "aws_account_id" {}

variable "aws_auth_iam_role" {
  default = "NoRole"
}

output "vault_user_data" {
  value = "${data.template_file.vault_init_config.rendered}"
}
