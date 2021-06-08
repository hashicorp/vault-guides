# This policy is based on the Admin policy from the Learn guide: https://learn.hashicorp.com/tutorials/vault/policies#write-a-policy
# Lookup self 

# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at `kv/` path

# List, create, update, and delete key/value secrets
path "kv/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage the Database secrets engine at `postgres/` path

# List, create, update, and delete key/value secrets
path "postgres/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage Entities and Entity alias
path "identity/entity-alias"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "identity/entity-alias/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "identity/entity"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "identity/entity/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}