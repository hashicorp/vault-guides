# Enable kv-v2 secrets engine in the education namespace
resource "vault_mount" "kv-v2" {
  depends_on = [vault_namespace.education]
  namespace = vault_namespace.education.path
  path = "kv-v2"
  type = "kv-v2"
}

# Enable kv-v2 secrets engine in the 'admin/test' namespace at 'secret' path
resource "vault_mount" "secret" {
  depends_on = [vault_namespace.test]
  namespace = vault_namespace.test.path
  path = "secret"
  type = "kv-v2"
}

# Enable Transit secrets engine at 'transit' in the 'admin/education' namespace
resource "vault_mount" "transit" {
  depends_on = [vault_namespace.education]
  namespace = vault_namespace.education.path
  path = "transit"
  type = "transit"
}

# # Creating an encryption key named 'payment'
resource "vault_transit_secret_backend_key" "key" {
  depends_on = [vault_mount.transit]
  namespace = vault_namespace.education.path
  backend    = "transit"
  name       = "payment"
  deletion_allowed = true
}
