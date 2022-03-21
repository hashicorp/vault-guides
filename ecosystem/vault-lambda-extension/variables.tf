# AWS region and AZs in which to deploy
variable "aws_region" {
  default = "us-east-1"
}

# All resources will be tagged with this
variable "environment_name" {
  default = "vault-lambda-extension-demo"
}

# URL for Vault OSS binary
variable "vault_zip_file" {
  default = "https://releases.hashicorp.com/vault/1.10.0/vault_1.10.0_linux_amd64.zip"
}

# Instance size
variable "instance_type" {
  default = "t2.micro"
}

# DB instance size
variable "db_instance_type" {
  default = "db.t2.micro"
}
