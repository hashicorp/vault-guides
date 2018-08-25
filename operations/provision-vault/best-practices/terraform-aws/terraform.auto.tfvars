# ---------------------------------------------------------------------------------------------------------------------
# General Variables
# ---------------------------------------------------------------------------------------------------------------------
# create         = true
# name           = "vault-best-practices"
# download_certs = true

# ---------------------------------------------------------------------------------------------------------------------
# Network Variables
# ---------------------------------------------------------------------------------------------------------------------
# vpc_cidr          = "172.19.0.0/16"
# vpc_cidrs_public  = ["172.19.0.0/20", "172.19.16.0/20", "172.19.32.0/20",]
# vpc_cidrs_private = ["172.19.48.0/20", "172.19.64.0/20", "172.19.80.0/20",]

# CIDRs to be given external access if the '*_public' variable is true; Terraform will
# automatically add the CIDR of the machine it is being run on to this list, or
# you can alternatively discover your IP by googling "what is my ip"
# public_cidrs = ["0.0.0.0/0",] # Open cluster to the public internet (NOT ADVISED!)

# nat_count              = 1 # Number of NAT gateways to provision across public subnets, defaults to public subnet count.
# bastion_servers        = 1 # Number of bastion hosts to provision across public subnets, defaults to public subnet count.
# bastion_instance       = "t2.micro"
# bastion_release        = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# bastion_consul_version = "1.2.0" # Consul version tag (e.g. 1.2.0 or 1.2.0-ent) - https://releases.hashicorp.com/consul/
# bastion_vault_version  = "0.10.3" # Vault version tag (e.g. 0.10.3 or 0.10.3-ent) - https://releases.hashicorp.com/vault/
# bastion_os             = "Ubuntu" # OS (e.g. RHEL, Ubuntu), defaults to RHEL
# bastion_os_version     = "16.04" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu), defaults to 7.3
# bastion_image_id       = "" # AMI ID override, defaults to base RHEL AMI

# network_tags = {"owner" = "hashicorp", "TTL" = "24"}

# ---------------------------------------------------------------------------------------------------------------------
# Consul Variables
# ---------------------------------------------------------------------------------------------------------------------
# consul_servers    = 3 # Number of Consul servers to provision across public subnets, defaults to public subnet count.
# consul_instance   = "t2.micro"
# consul_release    = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# consul_version    = "1.2.0" # Consul version tag (e.g. 1.2.0 or 1.2.0-ent) - https://releases.hashicorp.com/consul/
# consul_os         = "Ubuntu" # OS (e.g. RHEL, Ubuntu)
# consul_os_version = "16.04" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
# consul_image_id   = "" # AMI ID override, defaults to base RHEL AMI

# If 'consul_public' is true, assign a public IP, open port 22 for public access,
# & provision into public subnets to provide easier accessibility from the
# 'public_cidrs' without going through a Bastion host - DO NOT DO THIS IN PROD
# consul_public = true

# consul_server_config_override = <<EOF
# {
#   "log_level": "DEBUG",
#   "disable_remote_exec": false
# }
# EOF

# consul_client_config_override = <<EOF
# {
#   "log_level": "DEBUG",
#   "disable_remote_exec": false
# }
# EOF

# consul_tags = {"owner" = "hashicorp", "TTL" = "24"}

# consul_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]

# ---------------------------------------------------------------------------------------------------------------------
# Vault Variables
# ---------------------------------------------------------------------------------------------------------------------
# vault_servers    = 3 # Number of Vault servers, defaults to public count
# vault_instance   = "t2.micro"
# vault_release    = "0.1.0" # Release version tag (e.g. 0.1.0, 0.1.0-rc1, 0.1.0-beta1, 0.1.0-dev1)
# vault_version    = "0.10.3" #  Version tag (e.g. 0.10.3 or 0.10.3-ent) - https://releases.hashicorp.com/vault/
# vault_os         = "Ubuntu" # OS (e.g. RHEL, Ubuntu)
# vault_os_version = "16.04" # OS Version (e.g. 7.3 for RHEL, 16.04 for Ubuntu)
# vault_image_id   = "" # AMI ID override, defaults to base RHEL AMI

# If 'vault_public' is true, assign a public IP, open port 22 for public access,
# & provision into public subnets to provide easier accessibility from the
# 'public_cidrs' without going through a Bastion host - DO NOT DO THIS IN PROD
# vault_public = true

# vault_server_config_override = <<EOF
# # These values will override the defaults
# cluster_name = "dc1"
# EOF

# vault_tags = {"owner" = "hashicorp", "TTL" = "24"}

# vault_tags_list = [
#   {"key" = "owner", "value" = "hashicorp", "propagate_at_launch" = true},
#   {"key" = "TTL", "value" = "24", "propagate_at_launch" = true}
# ]
