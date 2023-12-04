# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "aws_account_id" {}

variable "aws_auth_iam_role" {
  default = "NoRole"
}

output "vault_user_data" {
  value = "${data.template_file.vault_init_config.rendered}"
}
