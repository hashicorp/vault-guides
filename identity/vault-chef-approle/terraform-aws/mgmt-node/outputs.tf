# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "vault-public-ip" {
  value = aws_instance.vault.public_ip
}

