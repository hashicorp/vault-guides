# General
variable "name"         { }
variable "provider"     { default = "aws" }
variable "local_ip_url" { default = "http://169.254.169.254/latest/meta-data/local-ipv4" }

# Network module
variable "vpc_cidr"                { }
variable "vpc_cidrs_public"        { type = "list" }
variable "nat_count"               { }
variable "vpc_cidrs_private"       { type = "list" }
variable "bastion_release_version" { }
variable "bastion_consul_version"  { }
variable "bastion_vault_version"   { }
variable "bastion_nomad_version"   { }
variable "bastion_os"              { }
variable "bastion_os_version"      { }
variable "bastion_count"           { }
variable "bastion_instance_type"   { }

# Consul module
variable "consul_release_version" { }
variable "consul_version"         { }
variable "consul_os"              { }
variable "consul_os_version"      { }
variable "consul_count"           { }
variable "consul_instance_type"   { }

# Vault module
variable "vault_release_version" { }
variable "vault_version"         { }
variable "vault_os"              { }
variable "vault_os_version"      { }
variable "vault_count"           { }
variable "vault_instance_type"   { }
