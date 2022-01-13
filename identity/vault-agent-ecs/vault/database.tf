resource "vault_mount" "postgres" {
  path = "${var.name}/database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.postgres.path
  name          = "product"
  allowed_roles = ["*"]

  postgresql {
    connection_url = "postgresql://${var.product_db_username}:${var.product_db_password}@${var.product_db_hostname}:${var.product_db_port}/products?sslmode=disable"
  }
}

resource "vault_database_secret_backend_role" "product" {
  backend             = vault_mount.postgres.path
  name                = "product"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = ["CREATE ROLE \"{{username}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{username}}\";"]
  default_ttl         = 604800
  max_ttl             = 604800
}

locals {
  products_creds_path = "${vault_mount.postgres.path}/creds/${vault_database_secret_backend_role.product.name}"
}

data "vault_policy_document" "product" {
  rule {
    path         = local.products_creds_path
    capabilities = ["read"]
    description  = "read all credentials for product database as product-api"
  }
}

resource "vault_policy" "product" {
  name   = "product"
  policy = data.vault_policy_document.product.hcl
}
