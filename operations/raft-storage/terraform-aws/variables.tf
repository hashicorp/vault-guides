# AWS region and AZs in which to deploy
variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zones" {
  default = "us-east-1a"
}

# All resources will be tagged with this
variable "environment_name" {
  default = "raft-demo"
}

# Number of Vault servers to provision
variable "vault_server_count" {
  default = 3
}

# URL for Vault OSS binary
variable "vault_zip_file" {
  #default = "https://releases.hashicorp.com/vault/1.2.0-beta1/vault_1.2.0-beta1_linux_amd64.zip"
  default = "https://releases.hashicorp.com/vault/1.2.0-beta2/vault_1.2.0-beta2_linux_amd64.zip"
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
