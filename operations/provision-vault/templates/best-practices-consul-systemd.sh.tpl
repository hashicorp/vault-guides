#!/bin/bash

echo "[---Begin best-practices-consul-systemd.sh---]"

NODE_NAME=$(hostname)
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_TLS_DIR=/opt/consul/tls
CONSUL_CONFIG_DIR=/etc/consul.d
WETTY_TLS_DIR=/opt/wetty/tls

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Create TLS dirs for certs"
sudo mkdir -pm 0755 $CONSUL_TLS_DIR $WETTY_TLS_DIR

echo "Write certs to TLS directories"
cat <<EOF | sudo tee $CONSUL_TLS_DIR/consul-ca.crt $WETTY_TLS_DIR/wetty-ca.crt
${ca_crt}
EOF
cat <<EOF | sudo tee $CONSUL_TLS_DIR/consul.crt $WETTY_TLS_DIR/wetty.crt
${leaf_crt}
EOF
cat <<EOF | sudo tee $CONSUL_TLS_DIR/consul.key $WETTY_TLS_DIR/wetty.key
${leaf_key}
EOF

sudo chown -R consul:consul $CONSUL_TLS_DIR $CONSUL_CONFIG_DIR
sudo chown -R root:root $WETTY_TLS_DIR

echo "Configure Consul server"
cat <<CONFIG | sudo tee $CONSUL_CONFIG_DIR/default.json
{
  "datacenter": "${name}",
  "node_name": "$NODE_NAME",
  "data_dir": "/opt/consul/data",
  "log_level": "INFO",
  "advertise_addr": "$LOCAL_IPV4",
  "client_addr": "0.0.0.0",
  "ui": true,
  "server": true,
  "bootstrap_expect": ${consul_bootstrap},
  "leave_on_terminate": true,
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
  },
  "service": {"name": "consul", "tags": ["server"], "port": 8080}
}
CONFIG

if [ ${consul_override} == true ] || [ ${consul_override} == 1 ]; then
  echo "Add custom Consul server override config"
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

echo "Configure Wetty with SSL"
cat <<ENVVARS | sudo tee /opt/wetty/wetty.conf
FLAGS=-p 3030 --host 127.0.0.1 --sslkey $WETTY_TLS_DIR/wetty.key --sslcert $WETTY_TLS_DIR/wetty.crt
ENVVARS

sudo systemctl restart wetty

echo "[---best-practices-consul-systemd.sh Complete---]"
