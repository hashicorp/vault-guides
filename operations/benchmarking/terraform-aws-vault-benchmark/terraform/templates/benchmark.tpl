#!/bin/bash

sudo apt-get -y install telnet vim

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

new_hostname="benchmark-$${instance_id}"

sudo sed -i '1s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf

systemctl stop consul

rm -f /etc/consul.d/*
touch /etc/consul.d/consul.conf
rm -rf /opt/consul/*

hostnamectl set-hostname "$${new_hostname}"

sudo sed '1 i nameserver 127.0.0.1' -i /etc/resolv.conf

rm -f /etc/consul.d/consul-default.json
rm -f /etc/consul.d/consul-server.json

cat <<EOF> /etc/consul.d/consul.json
{
  "datacenter": "dc1",
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=aws tag_key=env tag_value=${env}"],
  "telemetry": {
    "dogstatsd_addr": "localhost:8125",
    "disable_hostname": true
  }
}
EOF

chown consul:consul /etc/consul.d/*
chown -R consul:consul /opt/consul
systemctl start consul

#Testing tools
sudo apt install -y wrk
sudo apt-get install -y build-essential libssl-dev git zlib1g-dev
git clone https://github.com/giltene/wrk2.git
cd wrk2
make
sudo cp wrk /usr/local/bin/wrk2

#Certs
cat >/etc/ca.crt <<'EOF'
${ca}
EOF
sudo cp /etc/ca.crt /usr/local/share/ca-certificates/hashicorp.crt
sudo update-ca-certificates
