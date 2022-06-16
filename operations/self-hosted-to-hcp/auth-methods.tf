#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - Username & password auth method
#------------------------------------------------------------------------

resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

# Create a user, 'admin'
resource "vault_generic_endpoint" "admin" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/admin"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["admins"],
  "password": "superS3cret!"
}
EOT
}

# Create a user, 'student'
resource "vault_generic_endpoint" "student" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/student"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["student-secrets"],
  "password": "ch4ngeMe~"
}
EOT
}
