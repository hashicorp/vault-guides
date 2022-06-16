#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - Secrets engines
#------------------------------------------------------------------------

# Enable K/V v2 secrets engine at the path 'kv-v2'
resource "vault_mount" "kv-v2" {
  path = "api-credentials"
  type = "kv-v2"
}

# Enable Transit secrets engine at the path 'transit'
resource "vault_mount" "transit" {
  path = "transit"
  type = "transit"
}

# Creating Transit secrets engine encryption key named 'payment'
resource "vault_transit_secret_backend_key" "key" {
  depends_on       = [vault_mount.transit]
  backend          = "transit"
  name             = "payment"
  deletion_allowed = true
}
