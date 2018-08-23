# Vault Policy file for dev role

# Access to secret/dev
path "secret/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Additional access for UI
path "secret/" {
  capabilities = ["list"]
}
path "secret/dev" {
  capabilities = ["list"]
}
path "sys/mounts" {
  capabilities = ["read", "list"]
}
