# Use Vault provider
provider "vault" {
}


# Create a policy document
data "vault_policy_document" "training" {
  rule {
    path         = "kv-v2/data/training/*"
    capabilities = ["create", "read", "update", "delete", "list"]
  }
  rule {
    path         = "kv-v2/*"
    capabilities = ["list", "read"]
  }
  rule {
    path         = "transit/encrypt/payment"
    capabilities = ["update"]
  }
  rule {
    path         = "transit/decrypt/payment"
    capabilities = ["update"]
  }
  rule {
    path         = "transit/*"
    capabilities = ["read", "list"]
  }
}

# Create 'training' policy
resource "vault_policy" "training" {
  name   = "training"
  policy = data.vault_policy_document.training.hcl
}

# Enable auth method
resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_generic_endpoint" "student" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/student"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["training"],
  "password": "changeme"
}
EOT

}

# Enable K/V v2 secrets engine at 'kv-v2'
resource "vault_mount" "kv-v2" {
  path = "kv-v2"
  type = "kv-v2"
}

# Enable Transit secrets engine
resource "vault_mount" "transit" {
  path = "transit"
  type = "transit"
}

# Creating an encryption key named 'payment'
resource "vault_transit_secret_backend_key" "key" {
  depends_on = [vault_mount.transit]
  backend    = "transit"
  name       = "payment"
}
