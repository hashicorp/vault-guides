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
# To leverage more than one namespace, define a vault provider per namespace
#
#   admin
#    ├── education
#    │   └── training
#    │       └── boundary
#    └── test
#------------------------------------------------------------------------------
terraform {
  required_providers {
    vault = "~> 3.8.0"
  }
}


provider "vault" {}

#--------------------------------------
# Create 'admin/education' namespace
#--------------------------------------
resource "vault_namespace" "education" {
  path = "education"
}

#---------------------------------------------------
# Create 'admin/education/training' namespace
#---------------------------------------------------
resource "vault_namespace" "training" {
  depends_on = [vault_namespace.education]
  namespace = vault_namespace.education.path
  path = "training"
}

#-----------------------------------------------------------
# Create 'admin/education/training/boundary' namespace
#-----------------------------------------------------------
resource "vault_namespace" "boundary" {
  depends_on = [vault_namespace.training]
  namespace = vault_namespace.training.path_fq
  path = "boundary"
}

# #--------------------------------------
# # Create 'admin/test' namespace
# #--------------------------------------
resource "vault_namespace" "test" {
  path = "test"
}