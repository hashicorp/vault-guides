# AWS region and AZs in which to deploy
variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zones" {
  default = "us-east-1a"
}

# All resources will be tagged with this
variable "environment_name" {
  default = "plugin-password-polices"
}

variable "vault_server_private_ip" {
  description = "The private ip of the Vault server"
  default = "10.0.101.21"
}

# URL for Vault OSS binary
variable "vault_binary_url" {
  default = "https://releases.hashicorp.com/vault/1.6.0/vault_1.6.0_linux_amd64.zip"
}

# Instance size
variable "instance_type" {
  default = "t2.micro"
}

# SSH key name to access EC2 instances (should already exist) in the AWS Region
variable "key_name" {
}

# Instance tags for HashiBot AWS resource reaper
# variable hashibot_reaper_owner {}
variable "hashibot_reaper_ttl" {
  default = 48
}

# The Vault server is configured with the scenario completed.
# Set this to:
#   - "yes" for configuration complete
#   - "no" for configuration required (Have the practitioner do it)
variable "configure_vault_server" {
  default = "no"
}
