#---------------------
# Create policies
#---------------------

# Create fpe-client policy in the root namespace
resource "vault_policy" "fpe_client_policy" {
  name   = "fpe-client"
  policy = file("policies/fpe-client-policy.hcl")
}

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

# Create admin policy in the education namespace
resource "vault_policy" "admin_policy_education" {
  provider = vault.education
  depends_on = [vault_namespace.education]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create admin policy in the 'education/training' namespace
resource "vault_policy" "admin_policy_training" {
  provider = vault.training
  depends_on = [vault_namespace.training]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create admin policy in the 'education/training/vault_cloud' namespace
resource "vault_policy" "admin_policy_vault_cloud" {
  provider = vault.vault_cloud
  depends_on = [vault_namespace.vault_cloud]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create admin policy in the 'education/training/boundary' namespace
resource "vault_policy" "admin_policy_boundary" {
  provider = vault.boundary
  depends_on = [vault_namespace.boundary]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}
