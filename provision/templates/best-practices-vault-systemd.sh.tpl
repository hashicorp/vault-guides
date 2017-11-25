#!/bin/bash

echo "[---Begin best-practices-vault-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
local_ipv4=$(curl -s ${local_ip_url})

echo "Install ca-certificates"
sudo yum -y check-update
sudo yum install -q -y ca-certificates
sudo update-ca-trust force-enable

# TODO: Remove
echo "Configure Consul TLS certificate in /etc/pki/ca-trust/source/anchors/consul.crt"
cat <<EOF | sudo tee /etc/pki/ca-trust/source/anchors/consul.crt
${consul_crt_pem}
EOF

echo "Configure Consul TLS certificate in /etc/pki/tls/certs/consul.crt"
cat <<EOF | sudo tee /etc/pki/tls/certs/consul.crt
${consul_crt_pem}
EOF

# TODO: Remove
cd /etc/pki/tls/certs
sudo ln -sv /etc/pki/tls/certs/consul.crt $(openssl x509 -in /etc/pki/tls/certs/consul.crt -noout -hash).0

echo "Configure Consul TLS certificate in /etc/pki/tls/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/pki/tls/certs/ca-bundle.crt

# Consul
${consul_crt_pem}
EOF

# TODO: Remove
echo "Configure Consul TLS certificate in /etc/ssl/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/ssl/certs/ca-bundle.crt

# Consul
${consul_crt_pem}
EOF

echo "Update CA trust"
sudo update-ca-trust enable
sudo update-ca-trust extract

echo "Configure Consul TLS certificate"

# TODO: Remove
cat <<EOF | sudo tee /etc/pki/tls/private/consul.crt
${consul_crt_pem}
EOF

cat <<EOF | sudo tee /etc/pki/tls/private/consul.key
${consul_key_pem}
EOF

echo "Configure Vault Consul client"
cat <<CONFIG >/etc/consul.d/consul-client.json
{
  "datacenter": "${name}",
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"],
  "encrypt": "${serf_encrypt_key}",
  "key_file": "/etc/pki/tls/private/consul.crt",
  "cert_file": "/etc/pki/tls/certs/consul.crt",
  "ca_file": "/etc/pki/tls/certs/ca-bundle.crt",
  "ports": { "https": 8080 }
}
CONFIG

echo "Update Consul configuration file permissions"
chown -R consul:consul /etc/consul.d
chmod -R 0644 /etc/consul.d/*
chmod 0755 /etc/pki/tls/private/consul.key /etc/pki/tls/certs/consul.crt

echo "Don't start Consul in -dev mode"
echo '' | sudo tee /etc/consul.d/consul.conf

echo "Restart Consul"
systemctl restart consul

# TODO: Remove
echo "Configure Vault TLS certificate in /etc/pki/ca-trust/source/anchors/vault.crt"
cat <<EOF | sudo tee /etc/pki/ca-trust/source/anchors/vault.crt
${vault_crt_pem}
EOF

echo "Configure Vault TLS certificate in /etc/pki/tls/certs/vault.crt"
cat <<EOF | sudo tee /etc/pki/tls/certs/vault.crt
${vault_crt_pem}
EOF

# TODO: Remove
cd /etc/pki/tls/certs
sudo ln -sv /etc/pki/tls/certs/vault.crt $(openssl x509 -in /etc/pki/tls/certs/vault.crt -noout -hash).0

echo "Configure Vault TLS certificate in /etc/pki/tls/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/pki/tls/certs/ca-bundle.crt

# Vault
${vault_crt_pem}
EOF

# TODO: Remove
echo "Configure Vault TLS certificate in /etc/ssl/certs/ca-bundle.crt"
cat <<EOF | sudo tee -a /etc/ssl/certs/ca-bundle.crt

# Vault
${vault_crt_pem}
EOF

echo "Update CA trust"
sudo update-ca-trust enable
sudo update-ca-trust extract

echo "Configure Vault TLS certificate"

# TODO: Remove
cat <<EOF | sudo tee /etc/pki/tls/private/vault.crt
${vault_crt_pem}
EOF

cat <<EOF | sudo tee /etc/pki/tls/private/vault.key
${vault_key_pem}
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
  tls_key_file  = "/etc/pki/tls/private/vault.key"
  tls_cert_file = "/etc/pki/tls/certs/vault.crt"
}
EOF

echo "Update Vault configuration file permissions"
chown -R vault:vault /etc/vault.d
chmod -R 0644 /etc/vault.d/*
chmod 0755 /etc/pki/tls/private/vault.key /etc/pki/tls/certs/vault.crt

echo "Configure VAULT_ADDR environment variable to point Vault CLI to local Vault cluster"
echo 'export VAULT_ADDR="https://127.0.0.1:8200"' | sudo tee /etc/profile.d/vault.sh

echo "Don't start Vault in -dev mode and configure address to be https"
echo 'FLAGS=-address="https://127.0.0.1:8200"' | sudo tee /etc/vault.d/vault.conf

echo "Restart Vault"
systemctl restart vault

echo "[---best-practices-vault-systemd.sh Complete---]"
