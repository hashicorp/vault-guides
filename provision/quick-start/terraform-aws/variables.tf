variable "name"         { }
variable "provider"     { default = "aws" }
variable "local_ip_url" { default = "http://169.254.169.254/latest/meta-data/local-ipv4" }
variable "os"           { default = "RHEL" } # Base RHEL OS
variable "ami_owner"    { default = "309956199498" } # Base RHEL owner
variable "ami_name"     { default = "*RHEL-7.3_HVM_GA-*" } # Base RHEL name

variable "consul_version"  { default = "1.0.1" }
variable "consul_url"      { default = "" }
variable "consul_image_id" { default = "" }

variable "vault_version"  { default = "0.9.0" }
variable "vault_url"      { default = "" }
variable "vault_image_id" { default = "" }
