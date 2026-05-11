# Copyright IBM Corp. 2017, 2026

output "ip" {
    value = "${azurerm_public_ip.tf_publicip.ip_address}"
}
