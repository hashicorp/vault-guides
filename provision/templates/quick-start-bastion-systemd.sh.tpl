#!/bin/bash

echo "[---Begin quick-start-bastion-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})

echo "Configure Bastion Consul client"
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

echo "Configure Vault CLI to point to remote Vault cluster"
sudo sed -i '1s/$/ -address="http:\/\/vault.service.consul:8200"/' /etc/vault.d/vault.conf

echo "Configure VAULT_ADDR environment variable to point Vault CLI to remote Vault cluster"
echo 'export VAULT_ADDR="http://vault.service.consul:8200"' | sudo tee /etc/profile.d/vault.sh

echo "Stop Vault now that the CLI is pointing to a live Vault cluster"
systemctl stop vault

echo "[---quick-start-bastion-systemd.sh Complete---]"
