# Permits CRUD operation on kv-v2
path "kv-v2/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Encrypt data with 'payment' key
path "transit/encrypt/payment" {
  capabilities = ["update"]
}

# Decrypt data with 'payment' key
path "transit/decrypt/payment" {
  capabilities = ["update"]
}

# Read and list keys under transit secrets engine 
path "transit/*" {
  capabilities = ["read", "list"]
}

# List enabled secrets engines
path "secret/metadata/*" {
   capabilities = ["list"]
}