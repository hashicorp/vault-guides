resource "vault_mount" "kvv2" {
  path        = var.kv_mount_path
  type        = var.kv_version
  description = "Key value secrets engine created by terraform"
}

# Adding a short delay before writing to the KV secrets engine 
# this is due to error "* Upgrading from non-versioned to versioned data. This backend will be unavailable for a brief period and will resume service shortly."
resource "time_sleep" "wait_2_seconds" {
  create_duration = "2s"
}

# Write example secrets to the KV secrets engine
resource "vault_generic_secret" "example" {
  for_each            = toset(var.entities)
  path = "${vault_mount.kvv2.path}/${each.key}/static"
  depends_on = [time_sleep.wait_2_seconds]
  data_json = <<EOT
{
  "app":   "${each.key}",
  "username":   "${each.key}",
  "password": "cheese"
}
EOT
}
