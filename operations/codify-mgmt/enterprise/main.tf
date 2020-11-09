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

#-----------------------------------------------------------------------------------
# To configure Transform secrets engine, you need vault provider v2.12.0 or later
#-----------------------------------------------------------------------------------
terraform {
  required_providers {
    vault = "~> 2.12"
  }
}

#------------------------------------------------------------------------------
# To leverage more than one namespace, define a vault provider per namespace
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

#---------------------------------------------------------------
# Create nested namespaces
#   education has childnamespace, 'training'
#       training has childnamespace, 'secure'
#           secure has childnamespace, 'vault_cloud' and 'boundary'
#---------------------------------------------------------------

resource "vault_namespace" "education" {
  path = "education"
}

provider "vault" {
  alias = "education"
  namespace = trimsuffix(vault_namespace.education.id, "/")
}

# Create a childnamespace, 'training' under 'education'
resource "vault_namespace" "training" {
  provider = vault.education
  path = "training"
}

provider "vault" {
  alias = "training"
  namespace = trimsuffix(vault_namespace.training.id, "/")
}

# Create a childnamespace, 'vault_cloud' and 'boundary' under 'education/training'
resource "vault_namespace" "vault_cloud" {
  provider = vault.training
  path = "vault_cloud"
}

provider "vault" {
  alias = "vault_cloud"
  namespace = trimsuffix(vault_namespace.vault_cloud.id, "/")
}

# Create 'education/training/boundary' namespace
resource "vault_namespace" "boundary" {
  provider = vault.training
  path = "boundary"
}

provider "vault" {
  alias = "boundary"
  namespace = trimsuffix(vault_namespace.boundary.id, "/")
}
