name              = "vault-aws-dev"
vpc_cidrs_public  = ["10.139.1.0/24",]
vpc_cidrs_private = ["10.139.11.0/24",]
nat_count         = "1"
bastion_count     = "0"
vault_public_ip   = "true"
vault_count       = "1"
