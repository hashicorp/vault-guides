resource "vault_mount" "kvv2" {
  path        = var.kv_mount_path
  type        = var.kv_version
  description = "Key value secrets engine created by terraform"
}

# Write example secrets to the KV secrets engine
resource "vault_generic_secret" "example" {
  for_each            = toset(var.entities)
  path = "${vault_mount.kvv2.path}/${each.key}/static"
  data_json = <<EOT
{
  "app":   "${each.key}",
  "username":   "${each.key}",
  "password": "cheese"
}
EOT
}
