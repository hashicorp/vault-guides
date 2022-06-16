#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - variables
#------------------------------------------------------------------------

variable "s3_bucket" {
  description = "Name of the S3 bucket for Terraform state storage."
  type        = string
  default     = "learn-vault"
}

variable "s3_key_name" {
  description = "Key name of the Terraform state storage object."
  type        = string
  default     = "terraform.tfstate"
}

variable "s3_key_id" {
  description = "AWS KMS key ID"
  type        = string
  default     = "1a1a1a1a-0a0a-1b1b-2c2c-3c3c3c3c3c3c"
}

variable "s3_region" {
  description = "Name of the AWS region."
  type        = string
  default     = "us-east-1"
}
