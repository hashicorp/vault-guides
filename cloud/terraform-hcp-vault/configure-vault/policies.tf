# Create an admins policy in the admin namespace
resource "vault_policy" "admin_policy" {
  namespace = vault_namespace.test.path
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# # Create an admins policy in the admin/education namespace
resource "vault_policy" "admin_policy_education" {
  namespace = vault_namespace.education.path
  depends_on = [vault_namespace.education]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# # Create an admins policy in the admin/education/training namespace
resource "vault_policy" "admin_policy_training" {
  namespace = vault_namespace.training.path_fq
  depends_on = [vault_namespace.training]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# # Create admins policy in the admin/education/training/boundary namespace
resource "vault_policy" "admin_policy_boundary" {
  namespace = vault_namespace.boundary.path_fq
  depends_on = [vault_namespace.boundary]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# # Create an admins policy in the admin/test namespace
resource "vault_policy" "admin_policy_test" {
  namespace = vault_namespace.test.path
  depends_on = [vault_namespace.test]
  name   = "admins"
  policy = file("policies/admin-policy.hcl")
}

# # Create a tester policy in the admin/test namespace
resource "vault_policy" "tester_policy" {
  namespace = vault_namespace.test.path
  depends_on = [vault_namespace.test]
  name   = "tester"
  policy = file("policies/tester.hcl")
}

# # Create an eaas-client policy in the admin/education namespace
resource "vault_policy" "eaas-client_policy" {
  namespace = vault_namespace.education.path
  depends_on = [vault_namespace.education]
  name   = "eaas-client"
  policy = file("policies/eaas-client-policy.hcl")
}