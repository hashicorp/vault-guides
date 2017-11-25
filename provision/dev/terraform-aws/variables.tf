variable "name"              { }
variable "vpc_cidrs_public"  { type = "list" }
variable "vpc_cidrs_private" { type = "list" }
variable "nat_count"         { }
variable "bastion_count"     { }
variable "vault_public_ip"   { }
variable "vault_count"       { }
variable "os"                { default = "RHEL" } # Base RHEL OS
variable "ami_owner"         { default = "309956199498" } # Base RHEL owner
variable "ami_name"          { default = "*RHEL-7.3_HVM_GA-*" } # Base RHEL name
variable "vault_version"     { default = "0.9.0" }
variable "vault_url"         { default = "" }
variable "vault_image_id"    { default = "" }
