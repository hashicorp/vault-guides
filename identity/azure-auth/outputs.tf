output "ip" {
    value = "${azurerm_public_ip.tf_publicip.ip_address}"
}
