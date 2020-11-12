variable "aws_region" {
  default = "us-east-1"
}

variable "aws_zone" {
  default = "us-east-1a"
}

variable "vault_url" {
  default = "https://releases.hashicorp.com/vault/1.6.0/vault_1.6.0_linux_amd64.zip"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR of the VPC"
  default     = "192.168.100.0/24"
}
