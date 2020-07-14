#---------------------
# Create policies
#---------------------

# Create admin policy in the root namespace
resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create admin policy in the finance namespace
resource "vault_policy" "admin_policy_finance" {
  provider = vault.finance
  depends_on = [vault_namespace.finance]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create admin policy in the engineering namespace
resource "vault_policy" "admin_policy_engineering" {
  provider = vault.engineering
  depends_on = [vault_namespace.engineering]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create fpe-client policy in the root namespace
resource "vault_policy" "fpe_client_policy" {
  name   = "fpe-client"
  policy = file("policies/fpe-client-policy.hcl")
}
