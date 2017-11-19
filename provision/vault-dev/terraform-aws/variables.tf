variable "name"              { }
variable "vpc_cidrs_public"  { type = "list" }
variable "vpc_cidrs_private" { type = "list" }
variable "nat_count"         { }
variable "bastion_count"     { }
variable "vault_public_ip"   { }
variable "vault_count"       { }
