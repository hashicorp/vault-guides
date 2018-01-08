#!/bin/bash

echo "[---Begin quick-start-vault-systemd.sh---]"

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_CONFIG_FILE=/etc/consul.d/consul-client.json
VAULT_CONFIG_FILE=/etc/vault.d/vault-server.hcl

echo "Configure Vault Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

echo "Update Consul configuration file permissions"
sudo chown consul:consul $CONSUL_CONFIG_FILE

echo "Don't start Consul in -dev mode"
cat <<SWITCHES | sudo tee /etc/consul.d/consul.conf
SWITCHES

echo "Restart Consul"
sudo systemctl restart consul

echo "Configure Vault server"
cat <<CONFIG | sudo tee $VAULT_CONFIG_FILE
# Configure Vault server with TLS disabled and the Consul storage backend: https://www.vaultproject.io/docs/configuration/storage/consul.html
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
CONFIG

echo "Update Vault configuration file permissions"
sudo chown vault:vault $VAULT_CONFIG_FILE

echo "Configure Vault environment variables to point Vault server CLI to local Vault cluster and skip TLS verification on login"
cat <<ENVVARS | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
ENVVARS

echo "Don't start Vault in -dev mode"
cat <<SWITCHES | sudo tee /etc/vault.d/vault.conf
SWITCHES

echo "Restart Vault"
sudo systemctl restart vault

echo "[---quick-start-vault-systemd.sh Complete---]"
