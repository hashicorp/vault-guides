#!/bin/bash

echo "[---Begin quick-start-consul-systemd.sh---]"

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

echo "Configure Consul server"
cat <<CONFIG >/etc/consul.d/consul-server.json
{
  "datacenter": "${name}",
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "server": true,
  "bootstrap_expect": ${bootstrap_expect},
  "leave_on_terminate": true,
  "retry_join": ["provider=${provider} tag_key=Consul-Auto-Join tag_value=${name}"],
  "encrypt": "${serf_encrypt_key}",
  "key_file": "/etc/pki/tls/private/consul.crt",
  "cert_file": "/etc/pki/tls/certs/consul.crt",
  "ca_file": "/etc/pki/tls/certs/ca-bundle.crt",
  "ports": { "https": 8080 }
}
CONFIG

echo "Update configuration file permissions"
chown -R consul:consul /etc/consul.d
chmod -R 0644 /etc/consul.d/*
chmod 0755 /etc/pki/tls/private/consul.key /etc/pki/tls/certs/consul.crt

echo "Don't start Consul in -dev mode"
echo '' | sudo tee /etc/consul.d/consul.conf

echo "Restart Consul"
systemctl restart consul

echo "[---quick-start-consul-systemd.sh Complete---]"
