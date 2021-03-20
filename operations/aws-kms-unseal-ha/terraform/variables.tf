variable aws_region {
  default = "us-east-1"
}

variable aws_zone {
  default = "us-east-1a"
}

# variable "subnets_cidr" {
#   type = list
#   default = [
#     "10.200.1.0/24", 
#     "10.200.2.0/24", 
#     "10.200.3.0/24",
#     "10.200.4.0/24",
#     "10.200.5.0/24"
#     ]
# }

variable vpc_cidr {
  description = "CIDR of the VPC"
  default     = "10.200.0.0/16"
}

variable vault_url {
  description = "URL to download Vault Enterprise"
  default = "https://releases.hashicorp.com/vault/1.6.3/vault_1.6.3_linux_amd64.zip"
}

variable cluster_size {
  description = "Number of instances to launch in the AWS zone/AZ"
  default = "3"
}