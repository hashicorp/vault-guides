#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - Terraform Vault Provider
#
# Dev mode Vault server configuration
#------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket     = var.s3_bucket
    key        = var.s3_key_name
    kms_key_id = var.s3_key_id
    encrypt    = true
    region     = var.s3_region
  }
}

# It is strongly recommended to configure the Vault provider
# by exporting the appropriate environment variables:
# VAULT_ADDR, VAULT_TOKEN, VAULT_CACERT, VAULT_CAPATH, VAULT_NAMESPACE, etc.

provider "vault" {}
