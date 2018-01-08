#!/bin/bash

echo "[---Begin quick-start-consul-systemd.sh---]"

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Set variables"
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_TLS_FILE=/opt/consul/tls
CONSUL_CACERT_FILE="$CONSUL_TLS_FILE/ca.crt"
CONSUL_CLIENT_CERT_FILE="$CONSUL_TLS_FILE/consul.crt"
CONSUL_CLIENT_KEY_FILE="$CONSUL_TLS_FILE/consul.key"
CONSUL_CONFIG_FILE=/etc/consul.d/consul-server.json

echo "Create TLS dir for Consul certs"
sudo mkdir -pm 0755 $CONSUL_TLS_FILE

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

echo "Configure Consul server"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_FILE
{
  "datacenter": "${name}",
  "advertise_addr": "$LOCAL_IPV4",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "server": true,
  "bootstrap_expect": ${consul_bootstrap},
  "leave_on_terminate": true,
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
sudo chown -R consul:consul $CONSUL_CONFIG_FILE $CONSUL_TLS_FILE

echo "Don't start Consul in -dev mode"
cat <<SWITCHES | sudo tee /etc/consul.d/consul.conf
SWITCHES

echo "Restart Consul"
sudo systemctl restart consul

echo "[---quick-start-consul-systemd.sh Complete---]"
