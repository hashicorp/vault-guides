#------------------------------------------------------------------------------
# The best practice is to use remote state file and encrypt it since your
# state files may contains sensitive data (secrets).
#------------------------------------------------------------------------------
# terraform {
#       backend "s3" {
#             bucket = "remote-terraform-state-dev"
#             encrypt = true
#             key = "terraform.tfstate"
#             region = "us-east-1"
#       }
# }

#------------------------------------------------------------------------------
# To leverate more than one namespace, define a vault provider per namespace
#------------------------------------------------------------------------------
provider "vault" {
  alias = "finance"
  namespace = "finance"
}

provider "vault" {
  alias = "engineering"
  namespace = "engineering"
}

#------------------------------------------------------------------------------
# Create namespaces: finance, and engineering
#------------------------------------------------------------------------------
resource "vault_namespace" "finance" {
  path = "finance"
}

resource "vault_namespace" "engineering" {
  path = "engineering"
}

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

#--------------------------------
# Enable userpass auth method
#--------------------------------
resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_generic_endpoint" "student" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/student"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["fpe-client", "admins"],
  "password": "changeme"
}
EOT
}


#----------------------------------------------------------
# Enable secrets engines
#----------------------------------------------------------

# Enable kv-v2 secrets engine in the finance namespace
resource "vault_mount" "kv-v2" {
  depends_on = [vault_namespace.finance]
  provider = vault.finance
  path = "kv-v2"
  type = "kv-v2"
}

# Transform secrets engine at root
resource "vault_mount" "mount_transform" {
  path = "transform"
  type = "transform"
}

# Create an alphabet
resource "vault_transform_alphabet" "numerics" {
  path = vault_mount.mount_transform.path
  name = "numerics"
  alphabet = "0123456789"
}

# Create a transformation template
resource "vault_transform_template" "ccn" {
  path = vault_mount.mount_transform.path
  name = "ccn"
  type = "regex"
  pattern = "(\\d{4})-(\\d{4})-(\\d{4})-(\\d{4})"
  alphabet = vault_transform_alphabet.numerics.name
}

# Create a transformation named ccn-fpe
resource "vault_transform_transformation" "ccn-fpe" {
  path = vault_mount.mount_transform.path
  name = "ccn-fpe"
  type = "fpe"
  template = vault_transform_template.ccn.name
  tweak_source = "internal"
  # payments here listed by name and not reference to avoid circular dependency.
  # Vault does not require dependencies like these to exist prior to creating
  # other things that reference them, but they may simply not work until they do
  # exist.
  allowed_roles = ["payments"]
}

# Create a role named 'payments'
resource "vault_transform_role" "payments" {
  path = vault_mount.mount_transform.path
  name = "payments"
  transformations = [vault_transform_transformation.ccn-fpe.name]
}


#-------------------------------------------------------------------
# Test the transformation
#-------------------------------------------------------------------
data "vault_transform_encode" "encoded" {
  path = vault_transform_role.payments.path
  role_name = "payments"
  value = "1111-2222-3333-4444"
}

output "encoded" {
  value = data.vault_transform_encode.encoded.encoded_value
}

# resource "local_file" "encoded" {
#   content = data.vault_transform_encode.encoded.encoded_value
#   filename = "${path.module}/encoded"
# }
#
# data "vault_transform_decode" "decoded" {
#   path = vault_mount.mount_transform.path
#   role_name = vault_transform_role.payments.name
#   #value = data.vault_transform_encode.encoded.encoded_value
#   value = local_file.encoded.content
# }
#
# resource "local_file" "decoded" {
#   content = data.vault_transform_decode.decoded.decoded_value
#   filename = "${path.module}/decoded"
# }
