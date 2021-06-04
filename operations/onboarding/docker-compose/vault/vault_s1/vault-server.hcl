storage "consul" {
  address = "consul_a1:8500"
  path    = "vault" 
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

ui = "true"
log_level="INFO"
