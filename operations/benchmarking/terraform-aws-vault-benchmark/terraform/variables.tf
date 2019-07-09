variable "owner" {}
variable "ttl" {}
variable "env" {}

variable "azs" { type = "list" }
variable "region" {}

variable "consul_ami" {}
variable "vault_ami" {}

variable "consul_cluster_size" {
    default = "3"
}

variable "vault_ips" {
    default = {
        "0" = "10.0.1.15"
        "1" = "10.0.2.16"
        "2" = "10.0.3.17"
    }
}
