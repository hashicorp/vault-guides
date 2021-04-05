terraform {
  required_providers {
    hcp = {
      source = "localhost/providers/hcp"
    }
  }
}

resource "hcp_hvn" "learn_hcp_vault_hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "hcp_vault_cluster" "learn_hcp_vault" {
  hvn_id     = hcp_hvn.learn_hcp_vault_hvn.hvn_id
  cluster_id = "hcp-tf-example-vault-cluster"
}

# data "hcp_vault_cluster_admin_token" "learn_hcp_vault_admin_token" {
#   cluster_id = hcp_vault_cluster.example_vault_cluster.cluster_id
# }
#
# output "initial_root_token" {
#   value = learn_hcp_vault_admin_token
# }
