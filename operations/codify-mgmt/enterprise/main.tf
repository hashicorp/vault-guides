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
