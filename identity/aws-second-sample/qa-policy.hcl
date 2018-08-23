# Vault Policy file for qa role

# Access to secret/qa
path "secret/qa/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Additional access for UI
path "secret/" {
  capabilities = ["list"]
}
path "secret/qa" {
  capabilities = ["list"]
}
path "sys/mounts" {
  capabilities = ["read", "list"]
}

