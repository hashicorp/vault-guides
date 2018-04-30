#!/bin/bash

echo "[---Begin best-practices-bastion-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_TLS_PATH=/opt/consul/tls
CONSUL_CACERT_FILE="$CONSUL_TLS_PATH/ca.crt"
CONSUL_CLIENT_CERT_FILE="$CONSUL_TLS_PATH/consul.crt"
CONSUL_CLIENT_KEY_FILE="$CONSUL_TLS_PATH/consul.key"
CONSUL_CONFIG_FILE=/etc/consul.d/consul-client.json
VAULT_TLS_PATH=/opt/vault/tls
VAULT_CACERT_FILE="$VAULT_TLS_PATH/ca.crt"
VAULT_CLIENT_CERT_FILE="$VAULT_TLS_PATH/vault.crt"
VAULT_CLIENT_KEY_FILE="$VAULT_TLS_PATH/vault.key"

echo "Create TLS dir for Consul certs"
sudo mkdir -pm 0755 $CONSUL_TLS_PATH

echo "Write Consul CA certificate to $CONSUL_CACERT_FILE"
cat <<EOF | sudo tee $CONSUL_CACERT_FILE
${consul_ca_crt}
EOF

echo "Write Consul certificate to $CONSUL_CLIENT_CERT_FILE"
cat <<EOF | sudo tee $CONSUL_CLIENT_CERT_FILE
${consul_leaf_crt}
EOF

echo "Write Consul certificate key to $CONSUL_CLIENT_KEY_FILE"
cat <<EOF | sudo tee $CONSUL_CLIENT_KEY_FILE
${consul_leaf_key}
EOF

echo "Configure Bastion Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"],
  "encrypt": "${consul_encrypt}",
  "ca_file": "$CONSUL_CACERT_FILE",
  "cert_file": "$CONSUL_CLIENT_CERT_FILE",
  "key_file": "$CONSUL_CLIENT_KEY_FILE",
  "verify_incoming": true,
  "verify_outgoing": true,
  "ports": { "https": 8080 }
}
CONFIG

echo "Update Consul configuration & certificates file owner"
sudo chown -R consul:consul $CONSUL_CONFIG_FILE $CONSUL_TLS_PATH

echo "Don't start Consul in -dev mode"
cat <<SWITCHES | sudo tee /etc/consul.d/consul.conf
SWITCHES

echo "Restart Consul"
sudo systemctl restart consul

echo "Create tls dir for Vault certs"
sudo mkdir -pm 0755 $VAULT_TLS_PATH

echo "Write Vault CA certificate to $VAULT_CACERT_FILE"
cat <<EOF | sudo tee $VAULT_CACERT_FILE
${vault_ca_crt}
EOF

echo "Write Vault certificate to $VAULT_CLIENT_CERT_FILE"
cat <<EOF | sudo tee $VAULT_CLIENT_CERT_FILE
${vault_leaf_crt}
EOF

echo "Write Vault certificate key to $VAULT_CLIENT_KEY_FILE"
cat <<EOF | sudo tee $VAULT_CLIENT_KEY_FILE
${vault_leaf_key}
EOF

echo "Update Vault certificates file owner"
sudo chown -R vault:vault $VAULT_TLS_PATH

echo "Configure Vault environment variables to point Vault client CLI to remote Vault cluster & set TLS certs on login"
cat <<ENVVARS | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="https://vault.service.consul:8200"
export VAULT_CACERT="$VAULT_CACERT_FILE"
export VAULT_CLIENT_CERT="$VAULT_CLIENT_CERT_FILE"
export VAULT_CLIENT_KEY="$VAULT_CLIENT_KEY_FILE"
ENVVARS

echo "Don't start Vault in -dev mode"
cat <<SWITCHES | sudo tee /etc/vault.d/vault.conf
SWITCHES

echo "Stop Vault now that the CLI is pointing to a live Vault cluster & Nomad since it's not being used"
sudo systemctl stop vault
sudo systemctl stop nomad

echo "[---best-practices-bastion-systemd.sh Complete---]"
