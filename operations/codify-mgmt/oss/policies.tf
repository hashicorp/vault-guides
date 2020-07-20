#---------------------
# Create policies
#---------------------

# Create admin policy in the root namespace
resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create 'training' policy
resource "vault_policy" "eaas-client" {
  name   = "eaas-client"
  policy = file("policies/eaas-client-policy.hcl")
}
