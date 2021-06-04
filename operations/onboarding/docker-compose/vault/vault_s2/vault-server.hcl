storage "consul" {
  address = "consul_a2:8500"
  path    = "vault" 
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

ui = "true"
log_level="INFO"
