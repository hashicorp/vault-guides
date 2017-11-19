module "ssh_keypair_aws_override" {
  source = "git@github.com:hashicorp-modules/ssh-keypair-aws.git?ref=f-refactor"

  name = "${var.name}-override"
}

module "consul_auto_join_instance_role" {
  source = "git@github.com:hashicorp-modules/consul-auto-join-instance-role-aws?ref=f-refactor"

  name = "${var.name}"
}

module "tls_private_key" {
  source = "git@github.com:hashicorp-modules/tls-private-key.git?ref=f-refactor"

  name      = "${var.name}-vault-cert"
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "vault" {
  key_algorithm     = "${module.tls_private_key.algorithm}"
  private_key_pem   = "${module.tls_private_key.private_key_pem}"
  is_ca_certificate = "true"

  subject {
    common_name  = "hashicorp.com"
    organization = "HashiCorp"
  }

  validity_period_hours = 8760

  dns_names = [
    "*.node.consul",
    "*.service.consul"
  ]

  ip_addresses = [
    "0.0.0.0",
    "127.0.0.1"
  ]

  allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel",
    "ipsec_user",
    "timestamping",
    "ocsp_signing",
    "microsoft_server_gated_crypto",
    "netscape_server_gated_crypto",
  ]
}

data "template_file" "bastion_user_data" {
  template = "${file("${path.module}/../templates/bastion-init-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    vault_config = <<SCRIPT
echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Install ca-certificates"
sudo yum -y check-update
sudo yum install -q -y ca-certificates
sudo update-ca-trust force-enable

echo "Configure Vault TLS certificate in /etc/pki/ca-trust/source/anchors/vault.crt"
cat <<EOF | sudo tee /etc/pki/ca-trust/source/anchors/vault.crt
${tls_self_signed_cert.vault.cert_pem}
EOF

echo "Configure Vault TLS certificate in /etc/pki/tls/certs/vault.crt"
cat <<EOF | sudo tee /etc/pki/tls/certs/vault.crt
${tls_self_signed_cert.vault.cert_pem}
EOF
cd /etc/pki/tls/certs
sudo ln -sv /etc/pki/tls/certs/vault.crt $(openssl x509 -in /etc/pki/tls/certs/vault.crt -noout -hash).0

echo "Configure Vault TLS certificate in /etc/pki/tls/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/pki/tls/certs/ca-bundle.crt

# Vault
${tls_self_signed_cert.vault.cert_pem}
EOF

echo "Configure Vault TLS certificate in /etc/ssl/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/ssl/certs/ca-bundle.crt

# Vault
${tls_self_signed_cert.vault.cert_pem}
EOF

echo "Update CA trust"
sudo update-ca-trust enable
sudo update-ca-trust extract

echo "Configure Vault CLI to point to remote Vault cluster"
sudo sed -i '1s/$/ -address="https:\/\/vault.service.consul:8200"/' /etc/vault.d/vault.conf

echo "Configure VAULT_ADDR environment variable to point Vault server to remote Vault cluster"
echo 'export VAULT_ADDR="https://vault.service.consul:8200"' | sudo tee /etc/profile.d/vault.sh

echo "Stop Vault now that the CLI is pointing to a live Vault cluster"
systemctl stop vault
SCRIPT
  }
}

module "network_aws" {
  source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name              = "${var.name}"
  vpc_cidr          = "${var.vpc_cidr}"
  vpc_cidrs_public  = "${var.vpc_cidrs_public}"
  nat_count         = "${var.nat_count}"
  vpc_cidrs_private = "${var.vpc_cidrs_private}"
  release_version   = "${var.bastion_release_version}"
  consul_version    = "${var.bastion_consul_version}"
  vault_version     = "${var.bastion_vault_version}"
  nomad_version     = "${var.bastion_nomad_version}"
  os                = "${var.bastion_os}"
  os_version        = "${var.bastion_os_version}"
  bastion_count     = "${var.bastion_count}"
  instance_profile  = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type     = "${var.bastion_instance_type}"
  user_data         = "${data.template_file.bastion_user_data.rendered}" # Override user_data
  ssh_key_name      = "${module.ssh_keypair_aws_override.name}"
}

data "template_file" "consul_user_data" {
  template = "${file("${path.module}/../templates/consul-init-systemd.sh.tpl")}"

  vars = {
    name             = "${var.name}"
    bootstrap_expect = "${length(module.network_aws.subnet_private_ids)}"
  }
}

module "consul_aws" {
  source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr_block}"
  subnet_ids       = "${module.network_aws.subnet_private_ids}"
  release_version  = "${var.consul_release_version}"
  consul_version   = "${var.consul_version}"
  os               = "${var.consul_os}"
  os_version       = "${var.consul_os_version}"
  count            = "${var.consul_count}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.consul_instance_type}"
  user_data        = "${data.template_file.consul_user_data.rendered}" # Custom user_data
  ssh_key_name     = "${module.network_aws.ssh_key_name}"
}

data "template_file" "vault_user_data" {
  template = "${file("${path.module}/../templates/vault-init-systemd.sh.tpl")}"

  vars = {
    name         = "${var.name}"
    vault_config = <<SCRIPT
echo "Install ca-certificates"
sudo yum -y check-update
sudo yum install -q -y ca-certificates
sudo update-ca-trust force-enable

echo "Configure Vault TLS certificate in /etc/pki/ca-trust/source/anchors/vault.crt"
cat <<EOF | sudo tee /etc/pki/ca-trust/source/anchors/vault.crt
${tls_self_signed_cert.vault.cert_pem}
EOF

echo "Configure Vault TLS certificate in /etc/pki/tls/certs/vault.crt"
cat <<EOF | sudo tee /etc/pki/tls/certs/vault.crt
${tls_self_signed_cert.vault.cert_pem}
EOF
cd /etc/pki/tls/certs
sudo ln -sv /etc/pki/tls/certs/vault.crt $(openssl x509 -in /etc/pki/tls/certs/vault.crt -noout -hash).0

echo "Configure Vault TLS certificate in /etc/pki/tls/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/pki/tls/certs/ca-bundle.crt

# Vault
${tls_self_signed_cert.vault.cert_pem}
EOF

echo "Configure Vault TLS certificate in /etc/ssl/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/ssl/certs/ca-bundle.crt

# Vault
${tls_self_signed_cert.vault.cert_pem}
EOF

echo "Update CA trust"
sudo update-ca-trust enable
sudo update-ca-trust extract

echo "Configure Vault TLS certificate"
CERT_DIR=/etc/ssl/vault
mkdir -p $${CERT_DIR}
chmod -R 0755 $${CERT_DIR}

cat <<EOF | sudo tee $${CERT_DIR}/vault.crt
${tls_self_signed_cert.vault.cert_pem}
EOF

cat <<EOF | sudo tee $${CERT_DIR}/vault.key
${module.tls_private_key.private_key_pem}
EOF

echo "Configure Vault server"
cat <<EOF >/etc/vault.d/vault-server.hcl
# Configure Vault server with TLS and the Consul storage backend: https://www.vaultproject.io/docs/configuration/storage/consul.html
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 0
  tls_cert_file = "$${CERT_DIR}/vault.crt"
  tls_key_file  = "$${CERT_DIR}/vault.key"
}
EOF

echo "Update Vault configuration file permissions"
chown -R vault:vault /etc/vault.d
chmod -R 0644 /etc/vault.d/*

echo "Configure VAULT_ADDR environment variable to point Vault server to remote Vault cluster"
echo 'export VAULT_ADDR="https://127.0.0.1:8200"' | sudo tee /etc/profile.d/vault.sh

echo "Don't start Vault in -dev mode and configure Vault address to be https"
echo 'FLAGS=-address="https://127.0.0.1:8200"' | sudo tee /etc/vault.d/vault.conf

echo "Restart Vault"
systemctl restart vault
SCRIPT
  }
}

module "vault_aws" {
  source = "git@github.com:hashicorp-modules/network-aws.git?ref=f-refactor"

  name             = "${var.name}" # Must match network_aws module name for Consul Auto Join to work
  vpc_id           = "${module.network_aws.vpc_id}"
  vpc_cidr         = "${module.network_aws.vpc_cidr_block}"
  subnet_ids       = "${module.network_aws.subnet_private_ids}"
  release_version  = "${var.vault_release_version}"
  vault_version    = "${var.vault_version}"
  os               = "${var.vault_os}"
  os_version       = "${var.vault_os_version}"
  count            = "${var.vault_count}"
  instance_profile = "${module.consul_auto_join_instance_role.instance_profile_id}" # Override instance_profile
  instance_type    = "${var.vault_instance_type}"
  user_data        = "${data.template_file.vault_user_data.rendered}" # Custom user_data
  ssh_key_name     = "${module.network_aws.ssh_key_name}"
}
