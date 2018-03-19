variable "name"         { }
variable "provider"     { default = "aws" }
variable "local_ip_url" { default = "http://169.254.169.254/latest/meta-data/local-ipv4" }
variable "ami_owner"    { default = "309956199498" } # Base RHEL owner
variable "ami_name"     { default = "*RHEL-7.3_HVM_GA-*" } # Base RHEL name

variable "consul_version"  { default = "0.9.2" }
variable "consul_url"      { default = "" }
variable "consul_image_id" { default = "" }

variable "vault_version"  { default = "0.8.1" }
variable "vault_url"      { default = "" }
variable "vault_image_id" { default = "" }

variable "network_tags" {
  type    = "map"
  default = { }
}

variable "consul_tags" {
  type    = "list"
  default = [ ]
}

variable "vault_tags" {
  type    = "list"
  default = [ ]
}
