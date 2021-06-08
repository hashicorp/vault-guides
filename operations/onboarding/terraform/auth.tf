resource "vault_auth_backend" "approle" {
  type = "approle"
  path = var.approle_mount_path
}

resource "vault_approle_auth_backend_role" "entity-role" {
  backend        = vault_auth_backend.approle.path
  for_each = toset(var.entities)
  role_name      = each.key
  token_policies = ["default", vault_policy.kv_rw_policy.name, vault_policy.postgres_creds_policy.name]
}

resource "vault_approle_auth_backend_role_secret_id" "entity-role-secret-id" {
  backend        = vault_auth_backend.approle.path
  for_each = toset(var.entities)
  role_name      = each.key
  depends_on = [vault_approle_auth_backend_role.entity-role]
}

output "role_ids" {
  sensitive = "true"
  value = {
    for k, bd in vault_approle_auth_backend_role.entity-role : bd.role_name => bd.role_id
  }
}

output "secret_ids" {
  sensitive = "true"
  value = {
    for k, bd in vault_approle_auth_backend_role_secret_id.entity-role-secret-id : bd.role_name => bd.secret_id
  }
}

resource "local_file" "nginx_role_id" {
    content     = "${vault_approle_auth_backend_role.entity-role["nginx"].role_id}"
    filename = "${path.module}/../docker-compose/vault-agent/nginx-role_id"
}

resource "local_file" "nginx_secret_id" {
    content     = "${vault_approle_auth_backend_role_secret_id.entity-role-secret-id["nginx"].secret_id}"
    filename = "${path.module}/../docker-compose/vault-agent/nginx-secret_id"
}