# Create the vault entities
resource "vault_identity_entity" "entity" {
  for_each = toset(var.entities)
  name      = each.key
  policies = [vault_policy.kv_rw_policy.name, vault_policy.postgres_creds_policy.name]
}

# Create an approle alias
resource "vault_identity_entity_alias" "test" {
  for_each = toset(var.entities)
  name            = vault_approle_auth_backend_role.entity-role[each.key].role_id
  mount_accessor  = vault_auth_backend.approle.accessor
  canonical_id    = vault_identity_entity.entity[each.key].id
}

# KV Read/Write rule
data "vault_policy_document" "kv_rw_policy" {
  rule {
    path         = "${var.kv_mount_path}/data/{{identity.entity.name}}/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow KV V2 Read Write on secrets"
  }
}

# Postgres Database rule
data "vault_policy_document" "postgres_creds_policy" {
  rule {
    path         = "${var.postgres_mount_path}/creds/{{identity.entity.name}}"
    capabilities = ["read"]
    description  = "allow dynamic credentials"
  }
}

resource "vault_policy" "kv_rw_policy" {
  name = "kv_rw_policy"
  policy = data.vault_policy_document.kv_rw_policy.hcl
}

resource "vault_policy" "postgres_creds_policy" {
  name = "postgres_creds_policy"
  policy = data.vault_policy_document.postgres_creds_policy.hcl
}

resource "vault_token" "entity_token" {
  count = var.create_entity_token
  policies = [vault_policy.kv_rw_policy.name, vault_policy.postgres_creds_policy.name]
  renewable = true
  ttl = var.token_ttl
}

output "entity_token" {
  value = vault_token.entity_token[0].client_token
  sensitive = true
}