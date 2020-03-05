resource "tls_private_key" "root" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "root" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.root.private_key_pem

  validity_period_hours = 26280
  early_renewal_hours   = 8760

  is_ca_certificate = true

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  subject {
    common_name         = "HashiCorp. Root"
    organization        = "HashiCorp"
    organizational_unit = "HashiCorp SEs"
    street_address      = ["101 2nd St"]
    locality            = "San Francisco"
    province            = "CA"
    country             = "US"
    postal_code         = "94102"
  }
}

resource "tls_private_key" "vault" {
  algorithm = "RSA"
}

resource "tls_cert_request" "vault" {
  key_algorithm   = tls_private_key.vault.algorithm
  private_key_pem = tls_private_key.vault.private_key_pem

  subject {
    common_name         = "Vault"
    organization        = "HashiCorp"
    organizational_unit = "SE"
  }

  ip_addresses = ["127.0.0.1", "10.0.1.15", "10.0.2.16", "10.0.3.17"]
  dns_names    = ["active.vault.service.consul", "performance-standby.vault.service.consul", "standby.service.consul", "vault.service.consul"]
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem = tls_cert_request.vault.cert_request_pem

  ca_key_algorithm   = tls_private_key.root.algorithm
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "tls_private_key" "envoy" {
  algorithm = "RSA"
}

resource "tls_cert_request" "envoy" {
  key_algorithm   = tls_private_key.envoy.algorithm
  private_key_pem = tls_private_key.envoy.private_key_pem

  subject {
    common_name         = "Envoy"
    organization        = "HashiCorp"
    organizational_unit = "SE"
  }

  ip_addresses = ["127.0.0.1", "10.0.1.20"]
  dns_names    = ["envoy.service.consul"]
}

resource "tls_locally_signed_cert" "envoy" {
  cert_request_pem = tls_cert_request.envoy.cert_request_pem

  ca_key_algorithm   = tls_private_key.root.algorithm
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

