ui = true

listener "tcp" {
  address          = "10.145.32.150:8200"
  cluster_address  = "10.145.32.150:8201"
  tls_disable      = "true"
}

backend "file" {
  path = "vault"
}

api_addr = "http://10.145.32.150:8200"
cluster_addr = "https://10.145.32.150:8201"
