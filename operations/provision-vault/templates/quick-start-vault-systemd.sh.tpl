#!/bin/bash

echo "[---Begin quick-start-vault-systemd.sh---]"

echo "Set variables"
NODE_NAME=$(hostname)
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_CONFIG_FILE=/etc/consul.d/default.json
CONSUL_CONFIG_OVERRIDE_FILE=/etc/consul.d/z-override.json
VAULT_CONFIG_FILE=/etc/vault.d/default.hcl
VAULT_CONFIG_OVERRIDE_FILE=/etc/vault.d/z-override.hcl

echo "Configure Vault Consul client"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "node_name": "$NODE_NAME",
  "data_dir": "/opt/consul/data",
  "log_level": "INFO",
  "advertise_addr": "$LOCAL_IPV4",
  "client_addr": "0.0.0.0",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

echo "Update Consul configuration file permissions"
sudo chown consul:consul $CONSUL_CONFIG_FILE

if [ ${consul_override} == true ] || [ ${consul_override} == 1 ]; then
  echo "Add custom Consul client override config"
  cat <<CONFIG | sudo tee $CONSUL_CONFIG_OVERRIDE_FILE
${consul_config}
CONFIG

  echo "Update Consul configuration override file permissions"
  sudo chown consul:consul $CONSUL_CONFIG_OVERRIDE_FILE
fi

echo "Don't start Consul in -dev mode"
cat <<ENVVARS | sudo tee /etc/consul.d/consul.conf
CONSUL_HTTP_ADDR=127.0.0.1:8500
CONSUL_HTTP_SSL=false
CONSUL_HTTP_SSL_VERIFY=false
ENVVARS

echo "Configure Consul environment variables for HTTP API requests on login"
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_ADDR=http://127.0.0.1:8500
PROFILE

echo "Restart Consul"
sudo systemctl restart consul

echo "Configure Vault server"
cat <<CONFIG | sudo tee $VAULT_CONFIG_FILE
# https://www.vaultproject.io/docs/configuration/index.html
cluster_name = "${name}"
ui           = true

# https://www.vaultproject.io/docs/configuration/storage/consul.html
backend "consul" {
  scheme  = "http"
  address = "127.0.0.1:8500"
  path    = "vault/"
  service = "vault"
}

# https://www.vaultproject.io/docs/configuration/listener/tcp.html
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
CONFIG

echo "Update Vault configuration file permissions"
sudo chown vault:vault $VAULT_CONFIG_FILE

if [ ${vault_override} == true ] || [ ${vault_override} == 1 ]; then
  echo "Add custom Vault server override config"
  cat <<CONFIG | sudo tee $VAULT_CONFIG_OVERRIDE_FILE
${vault_config}
CONFIG

  echo "Update Vault configuration override file permissions"
  sudo chown vault:vault $VAULT_CONFIG_OVERRIDE_FILE
fi

echo "Configure Vault environment variables to point Vault server CLI to local Vault cluster and skip TLS verification on login"
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
PROFILE

echo "Don't start Vault in -dev mode"
echo '' | sudo tee /etc/vault.d/vault.conf

echo "Restart Vault"
sudo systemctl restart vault

echo "[---quick-start-vault-systemd.sh Complete---]"
