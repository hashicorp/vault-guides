# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "ip" {
    value = "${azurerm_public_ip.tf_publicip.ip_address}"
}
