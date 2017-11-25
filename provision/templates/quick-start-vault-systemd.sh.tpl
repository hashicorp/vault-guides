#!/bin/bash

echo "[---Begin quick-start-vault-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})

echo "Configure Vault Consul client"
cat <<CONFIG >/etc/consul.d/consul-client.json
{
  "datacenter": "${name}",
  "advertise_addr": "$${LOCAL_IPV4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

echo "Update Consul configuration file permissions"
chown -R consul:consul /etc/consul.d
chmod -R 0644 /etc/consul.d/*

echo "Don't start Consul in -dev mode"
echo '' | sudo tee /etc/consul.d/consul.conf

echo "Restart Consul"
systemctl restart consul

echo "Configure Vault server"
cat <<EOF >/etc/vault.d/vault-server.hcl
# Configure Vault server with TLS disabled and the Consul storage backend: https://www.vaultproject.io/docs/configuration/storage/consul.html
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
EOF

echo "Update Vault configuration file permissions"
chown -R vault:vault /etc/vault.d
chmod -R 0644 /etc/vault.d/*

echo "Configure VAULT_ADDR environment variable to point Vault CLI to local Vault cluster"
echo 'export VAULT_ADDR="https://127.0.0.1:8200"' | sudo tee /etc/profile.d/vault.sh

echo "Don't start Vault in -dev mode and configure address to be http"
echo 'FLAGS=-address="http://127.0.0.1:8200"' | sudo tee /etc/vault.d/vault.conf

echo "Restart Vault"
systemctl restart vault

echo "[---quick-start-vault-systemd.sh Complete---]"
