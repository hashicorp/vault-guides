#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - student ACL
# Example policy: Permits CRUD operations on kv-v2 under student path
#------------------------------------------------------------------------

# List, create, update, and delete key/value secrets
# at 'api-credentials/student' path.
path "api-credentials/data/student/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Encrypt data with 'payment' key.
path "transit/encrypt/payment" {
  capabilities = ["update"]
}

# Decrypt data with 'payment' key.
path "transit/decrypt/payment" {
  capabilities = ["update"]
}

# Read and list keys under transit secrets engine.
path "transit/*" {
  capabilities = ["read", "list"]
}

# List secrets engines.
path "api-credentials/metadata/*" {
  capabilities = ["list"]
}
