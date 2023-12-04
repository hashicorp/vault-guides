# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "vault_addr" {}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
