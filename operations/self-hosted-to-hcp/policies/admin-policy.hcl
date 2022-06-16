#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - admins ACL
# Example policy: Admin tasks for auth methods and secrets engines
#------------------------------------------------------------------------

# Create and manage  auth methods.
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List auth methods.
path "sys/auth" {
  capabilities = ["read"]
}

# Create and manage tokens.
path "/auth/token/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# Create and manage ACL policies.
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List ACL policies.
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Create and manage secrets engines.
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List secrets engines.
path "sys/mounts" {
  capabilities = ["read", "list"]
}

# List, create, update, and delete key/value secrets at api-credentials.
path "api-credentials/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage transit secrets engine.
path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Read Vault health status.
path "sys/health" {
  capabilities = ["read", "sudo"]
}
