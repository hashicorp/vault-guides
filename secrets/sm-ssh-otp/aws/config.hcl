storage "raft" {
  path    = "/Users/lynnfrank/hashicorp/vault/vault-guides/secrets/sm-ssh-otp/aws"
  node_id = "vault-server-00"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  cluster_address     = "0.0.0.0:8201"
  tls_disable = true
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"
disable_mlock = true
ui=true