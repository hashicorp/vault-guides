variable "enabled_auth_methods" {
  description = "Authentication methods enabled"
  type        = "list"
}

resource "vault_auth_backend" "approle" {
  count = "${length(var.enabled_auth_methods)}"
  type  = "${element(var.enabled_auth_methods, count.index)}"
  path  = "${element(var.enabled_auth_methods, count.index)}"
}

module "app-role" {
  source = "./app-role"
}
