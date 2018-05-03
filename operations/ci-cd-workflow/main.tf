terraform {
  required_version = ">= 0.9.3"
}

provider "vault" {
  address = "${var.address}"
  token   = "${var.token}"
}

module "policies" {
  source = "./policies"
}

module "auth-methods" {
  source               = "./auth-methods"
  enabled_auth_methods = "${var.enabled_auth_methods}"
}

module "secret-engines" {
  source               = "./secret-engines"
  db_connection_string = "${var.db_connection_string}"
}
