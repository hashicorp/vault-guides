#!/bin/bash

echo "[---Begin best-practices-vault-systemd.sh---]"

NODE_NAME=$(hostname)
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_TLS_DIR=/opt/consul/tls
CONSUL_CONFIG_DIR=/etc/consul.d
VAULT_TLS_DIR=/opt/vault/tls
VAULT_CONFIG_DIR=/etc/vault.d

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Write certs to TLS directories"
cat <<EOF | sudo tee $CONSUL_TLS_DIR/consul-ca.crt $VAULT_TLS_DIR/consul-ca.crt $VAULT_TLS_DIR/vault-ca.crt
${ca_crt}
EOF
cat <<EOF | sudo tee $CONSUL_TLS_DIR/consul.crt $VAULT_TLS_DIR/consul.crt $VAULT_TLS_DIR/vault.crt
${leaf_crt}
EOF
cat <<EOF | sudo tee $CONSUL_TLS_DIR/consul.key $VAULT_TLS_DIR/consul.key $VAULT_TLS_DIR/vault.key
${leaf_key}
EOF

sudo chown -R consul:consul $CONSUL_TLS_DIR $CONSUL_CONFIG_DIR
sudo chown -R vault:vault $VAULT_TLS_DIR $VAULT_CONFIG_DIR

echo "Configure Vault Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_DIR/default.json
{
  "datacenter": "${name}",
  "node_name": "$NODE_NAME",
  "data_dir": "/opt/consul/data",
  "log_level": "INFO",
  "advertise_addr": "$LOCAL_IPV4",
  "client_addr": "0.0.0.0",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"],
  "encrypt": "${consul_encrypt}",
  "encrypt_verify_incoming": true,
  "encrypt_verify_outgoing": true,
  "ca_file": "$CONSUL_TLS_DIR/consul-ca.crt",
  "cert_file": "$CONSUL_TLS_DIR/consul.crt",
  "key_file": "$CONSUL_TLS_DIR/consul.key",
  "verify_incoming": false,
  "verify_incoming_https": false,
  "verify_incoming_rpc": true,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ports": {
    "https": 8080
  },
  "addresses": {
    "https": "0.0.0.0"
  }
}
CONFIG

if [ ${consul_override} == true ] || [ ${consul_override} == 1 ]; then
  echo "Add custom Consul client override config"
  cat <<CONFIG | sudo tee $CONSUL_CONFIG_DIR/z-override.json
${consul_config}
CONFIG
fi

echo "Configure Consul environment variables for HTTPS API requests on login"
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_ADDR=https://127.0.0.1:8080
export CONSUL_CACERT=$CONSUL_TLS_DIR/consul-ca.crt
export CONSUL_CLIENT_CERT=$CONSUL_TLS_DIR/consul.crt
export CONSUL_CLIENT_KEY=$CONSUL_TLS_DIR/consul.key
PROFILE

echo "Don't start Consul in -dev mode and use SSL"
cat <<ENVVARS | sudo tee $CONSUL_CONFIG_DIR/consul.conf
CONSUL_HTTP_ADDR=127.0.0.1:8080
CONSUL_HTTP_SSL=true
CONSUL_HTTP_SSL_VERIFY=false
ENVVARS

sudo systemctl restart consul

echo "Configure Vault server"
cat <<CONFIG | sudo tee $VAULT_CONFIG_DIR/default.hcl
# https://www.vaultproject.io/docs/configuration/index.html
cluster_name = "${name}"
ui           = true

# https://www.vaultproject.io/docs/configuration/storage/consul.html
backend "consul" {
  scheme  = "https"
  address = "127.0.0.1:8080"
  path    = "vault/"
  service = "vault"

  tls_ca_file   = "$VAULT_TLS_DIR/consul-ca.crt"
  tls_cert_file = "$VAULT_TLS_DIR/consul.crt"
  tls_key_file  = "$VAULT_TLS_DIR/consul.key"
}

# https://www.vaultproject.io/docs/configuration/listener/tcp.html
listener "tcp" {
  address = "0.0.0.0:8200"

  tls_client_ca_file = "$VAULT_TLS_DIR/vault-ca.crt"
  tls_cert_file      = "$VAULT_TLS_DIR/vault.crt"
  tls_key_file       = "$VAULT_TLS_DIR/vault.key"

  tls_require_and_verify_client_cert = false
  tls_disable_client_certs           = true
}
CONFIG

if [ ${vault_override} == true ] || [ ${vault_override} == 1 ]; then
  echo "Add custom Vault server override config"
  cat <<CONFIG | sudo tee $VAULT_CONFIG_DIR/z-override.hcl
${vault_config}
CONFIG
fi

echo "Configure Vault environment variables to point Vault server CLI to local Vault cluster"
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=false
export VAULT_CACERT=$VAULT_TLS_DIR/vault-ca.crt
export VAULT_CLIENT_CERT=$VAULT_TLS_DIR/vault.crt
export VAULT_CLIENT_KEY=$VAULT_TLS_DIR/vault.key
PROFILE

echo "Don't start Vault in -dev mode"
echo '' | sudo tee $VAULT_CONFIG_DIR/vault.conf

sudo systemctl restart vault

echo "[---best-practices-vault-systemd.sh Complete---]"
