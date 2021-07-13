variable aws_region {
  default = "us-east-1"
}

variable aws_zone {
  default = "us-east-1a"
}

variable vpc_cidr {
  description = "CIDR of the VPC"
  default     = "192.168.100.0/24"
}

variable vault_url {
  description = "URL to download Vault Enterprise"
  default = "https://releases.hashicorp.com/vault/1.6.3/vault_1.6.3_linux_amd64.zip"
}

variable cluster_size {
  description = "Number of instances to launch in the AWS zone/AZ"
  default = "3"
}