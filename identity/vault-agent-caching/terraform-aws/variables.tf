# AWS region and AZs in which to deploy
variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zones" {
  default = "us-east-1a"
}

# All resources will be tagged with this
variable "environment_name" {
  default = "vault-agent-demo"
}

# Consul datacenter name
variable "consul_dc" {
  default = "dc1"
}

# Number of Vault servers to provision
variable "vault_server_count" {
  default = 1
}

# URL for Vault OSS binary
variable "vault_zip_file" {
  default = "https://releases.hashicorp.com/vault/1.1.0/vault_1.1.0_linux_amd64.zip"
}

# URL for Consul OSS binary
variable "consul_zip_file" {
  default = "https://releases.hashicorp.com/consul/1.4.3/consul_1.4.3_linux_amd64.zip"
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

