storage "consul" {
  address = "consul_a1:8500"
  path    = "vault" 
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "10.5.0.8:8201"
  tls_disable = "true"
}

api_addr = "http://10.5.0.8:8200"
cluster_addr = "https://10.5.0.8:8201"

ui = "true"
log_level="INFO"
