data "template_file" "user_data" {
  template = "${file("${path.module}/consumer_install.sh.tpl")}"

  vars = {
    application = "jq"
    vault_addr  = "${var.vault_addr}"
  }
}
