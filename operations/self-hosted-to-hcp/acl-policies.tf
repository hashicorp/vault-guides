#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - ACL policies
#------------------------------------------------------------------------

# Admin capabilities within default namespace
resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Students are admins of kv-v2 secrets engine
# and can also Read and list keys under transit
# + encrypt & decrypt with the 'payment' key
resource "vault_policy" "student_secrets_engines" {
  name   = "student-secrets"
  policy = file("policies/student-secrets.hcl")
}
