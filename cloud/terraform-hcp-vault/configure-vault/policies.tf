# Create an admins policy in the admin namespace
resource "vault_policy" "admin_policy" {
  provider = vault.admin
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create an admins policy in the admin/education namespace
resource "vault_policy" "admin_policy_education" {
  provider = vault.education
  depends_on = [vault_namespace.education]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create an admins policy in the admin/education/training namespace
resource "vault_policy" "admin_policy_training" {
  provider = vault.training
  depends_on = [vault_namespace.training]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create admins policy in the admin/education/training/boundary namespace
resource "vault_policy" "admin_policy_boundary" {
  provider = vault.boundary
  depends_on = [vault_namespace.boundary]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create an admins policy in the admin/test namespace
resource "vault_policy" "admin_policy_test" {
  provider = vault.test
  depends_on = [vault_namespace.test]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# Create a tester policy in the admin/test namespace
resource "vault_policy" "tester_policy" {
  provider = vault.test
  depends_on = [vault_namespace.test]
  name   = "tester"
  policy = file("policies/tester.hcl")
}

# Create an eaas-client policy in the admin/education namespace
resource "vault_policy" "eaas-client_policy" {
  provider = vault.education
  depends_on = [vault_namespace.education]
  name   = "eaas-client"
  policy = file("policies/eaas-client-policy.hcl")
}