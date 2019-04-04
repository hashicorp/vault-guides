# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "name"              { default = "vault-best-practices" }
variable "common_name"       { default = "example.com" }
variable "organization_name" { default = "Example Inc." }
variable "provider"          { default = "aws" }
variable "local_ip_url"      { default = "http://169.254.169.254/latest/meta-data/local-ipv4" }
variable "download_certs"    { default = false }

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "vpc_cidr" { default = "10.139.0.0/16" }

variable "vpc_cidrs_public" {
  type    = "list"
  default = ["10.139.1.0/24", "10.139.2.0/24", "10.139.3.0/24",]
}

variable "vpc_cidrs_private" {
  type    = "list"
  default = ["10.139.11.0/24", "10.139.12.0/24", "10.139.13.0/24",]
}

variable "nat_count"              { default = 1 }
variable "bastion_servers"        { default = 1 }
variable "bastion_instance"       { default = "t2.small" }
variable "bastion_release"        { default = "0.1.0" }
variable "bastion_consul_version" { default = "1.2.3" }
variable "bastion_vault_version"  { default = "0.11.3" }
variable "bastion_os"             { default = "RHEL" }
variable "bastion_os_version"     { default = "7.3" }
variable "bastion_image_id"       { default = "" }

variable "network_tags" {
  type    = "map"
  default = { }
}

# ---------------------------------------------------------------------------------------------------------------------
# Consul Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "consul_servers"    { default = -1 }
variable "consul_instance"   { default = "t2.small" }
variable "consul_release"    { default = "0.1.0" }
variable "consul_version"    { default = "1.2.3" }
variable "consul_os"         { default = "RHEL" }
variable "consul_os_version" { default = "7.3" }
variable "consul_image_id"   { default = "" }

variable "consul_public" {
  description = "If true, assign a public IP, open port 22 for public access, & provision into public subnets to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD"
  default     = false
}

variable "consul_server_config_override" { default = "" }
variable "consul_client_config_override" { default = "" }

variable "consul_tags" {
  type    = "map"
  default = { }
}

variable "consul_tags_list" {
  type    = "list"
  default = [ ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Vault Variables
# ---------------------------------------------------------------------------------------------------------------------
variable "vault_servers"    { default = -1 }
variable "vault_instance"   { default = "t2.small" }
variable "vault_release"    { default = "0.1.0" }
variable "vault_version"    { default = "0.11.3" }
variable "vault_os"         { default = "RHEL" }
variable "vault_os_version" { default = "7.3" }
variable "vault_image_id"   { default = "" }

variable "vault_public" {
  description = "If true, assign a public IP, open port 22 for public access, & provision into public subnets to provide easier accessibility without a Bastion host - DO NOT DO THIS IN PROD"
  default     = false
}

variable "vault_server_config_override" { default = "" }

variable "vault_tags" {
  type    = "map"
  default = { }
}

variable "vault_tags_list" {
  type    = "list"
  default = [ ]
}
