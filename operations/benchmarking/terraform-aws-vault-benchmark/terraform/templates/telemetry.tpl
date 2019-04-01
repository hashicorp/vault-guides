#!/bin/bash

sudo apt-get -y install telnet vim

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

new_hostname="telemetry-$${instance_id}"

sudo sed -i '1s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf

systemctl stop consul

rm -f /etc/consul.d/*
touch /etc/consul.d/consul.conf
rm -rf /opt/consul/data/*

hostnamectl set-hostname "$${new_hostname}"

sudo sed '1 i nameserver 127.0.0.1' -i /etc/resolv.conf


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

sudo cat <<EOF> /etc/consul.d/influxdb-service.json
{
  "service": {
    "name": "influxdb",
    "port": 8086,
    "checks": [
      {
      "id": "influxdb",
      "name": "Influx DB TCP Check",
      "tcp": "localhost:8086",
      "interval": "10s",
      "timeout": "1s"
      }
    ]
  }
}
EOF

sudo cat <<EOF> /etc/consul.d/grafana-service.json
{
  "service": {
    "name": "grafana",
    "port": 3000,
    "checks": [
      {
      "id": "grafana",
      "name": "grafana TCP Check",
      "tcp": "localhost:3000",
      "interval": "10s",
      "timeout": "1s"
      }
    ]
  }
}
EOF

sudo cat <<EOF> /etc/consul.d/prometheus-service.json
{
  "service": {
    "name": "prometheus",
    "port": 9090,
    "checks": [
      {
      "id": "prometheus",
      "name": "prometheus TCP Check",
      "tcp": "localhost:9090",
      "interval": "10s",
      "timeout": "1s"
      }
    ]
  }
}
EOF

chown consul:consul /etc/consul.d/*
systemctl start consul

#influx
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/$${DISTRIB_ID,,} $${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt-get -y update
sudo apt-get -y install influxdb
sudo service influxdb start

#prometheus
sudo apt install nginx
sudo systemctl start nginx
sudo systemctl enable nginx

sudo useradd --no-create-home --shell /bin/false prometheus
sudo useradd --no-create-home --shell /bin/false node_exporter

sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

cd
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.0.0/prometheus-2.0.0.linux-amd64.tar.gz
tar xvf prometheus-2.0.0.linux-amd64.tar.gz
sudo cp prometheus-2.0.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.0.0.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

sudo cp -r prometheus-2.0.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.0.0.linux-amd64/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

cat <<EOF> /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'envoy'
    metrics_path: '/stats'
    params:
        format: ['prometheus']
    scrape_interval: 15s
    scrape_timeout: 15s
    static_configs:
      - targets: ['10.0.1.20:9901']
EOF

cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries


[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start prometheus
sudo systemctl enable prometheus


#grafana
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get -y update
sudo apt-get -y install grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server.service

sleep 30

#Add our datasources
curl --user admin:admin 'http://127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"Prometheus","isDefault":false ,"type":"prometheus","url":"http://localhost:9090","access":"proxy"}'
curl --user admin:admin 'http://127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"InfluxDB","isDefault":false ,"type":"influxdb","url":"http://localhost:8086","access":"proxy","database":"telegraf","user":"telegraf","password":"telegraf"}'
