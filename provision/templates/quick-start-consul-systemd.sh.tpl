#!/bin/bash

echo "[---Begin quick-start-consul-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})

echo "Configure Consul server"
cat <<CONFIG >/etc/consul.d/consul-server.json
{
  "datacenter": "${name}",
  "advertise_addr": "$${LOCAL_IPV4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "server": true,
  "bootstrap_expect": ${bootstrap_expect},
  "leave_on_terminate": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"]
}
CONFIG

echo "Update configuration file permissions"
chown -R consul:consul /etc/consul.d
chmod -R 0644 /etc/consul.d/*

echo "Don't start Consul in -dev mode"
echo '' | sudo tee /etc/consul.d/consul.conf

echo "Restart Consul"
systemctl restart consul

echo "[---quick-start-consul-systemd.sh Complete---]"
