resource "vault_mount" "postgres" {
  path = "postgres"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.postgres.path
  name          = "postgres"
  allowed_roles = ["*"]

  postgresql {
    connection_url = "postgresql://postgres:password@db:5432/products?sslmode=disable"
  }
}

# Dynamic Database role
resource "vault_database_secret_backend_role" "role" {
  for_each            = toset(var.entities)
  backend             = vault_mount.postgres.path
  name                = each.key
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  revocation_statements = ["ALTER ROLE \"{{name}}\" NOLOGIN;"]
  default_ttl = var.postgres_ttl
  max_ttl = 300
}

