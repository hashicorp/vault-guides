variable "path" {
  description = "AppRole path"
  default     = "approle"
}

#resource "vault_approle_auth_backend_role" "approle_dev" {
#  backend   = "${var.path}"
#  role_name = "dev-role"
#  policies  = ["default", "dev"]
#}


#resource "vault_approle_auth_backend_role" "approle_prod" {
#  backend   = "${var.path}"
#  role_name = "prod-role"
#  policies  = ["default", "prod"]
#}

