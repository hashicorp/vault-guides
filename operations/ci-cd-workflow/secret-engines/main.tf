variable "database_path" {
  description = "Path used to mount database in Vault"
  default     = "database"
}

variable "db_connection_string" {
  description = "Connection string for database secret engine"
  default     = "postgres://username:password@host:port/database"
}

variable "db_sql_query" {
  description = "Query used to dynamically create users in DB"
  default     = "CREATE ROLE {{name}} WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"
}

resource "vault_mount" "db" {
  path = "postgres"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = "${vault_mount.db.path}"
  name          = "postgres"
  allowed_roles = ["dev", "prod"]

  postgresql {
    connection_url = "${var.db_connection_string}"
  }
}

resource "vault_database_secret_backend_role" "role" {
  backend             = "${vault_mount.db.path}"
  name                = "my-role"
  db_name             = "${vault_database_secret_backend_connection.postgres.name}"
  creation_statements = "${var.db_sql_query}"
}
