#!/bin/bash

sudo apt-get -y install telnet vim

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

new_hostname="consul-$${instance_id}"

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
  "bootstrap_expect": 3,
  "server": true,
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

#Telemetry
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/$${DISTRIB_ID,,} $${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

sudo apt-get update && sudo apt-get install telegraf
sudo service telegraf stop

sudo  cat <<EOF | sudo tee /etc/telegraf/telegraf.conf
# Telegraf Configuration

[global_tags]
  role = "consul-server"
  datacenter = "dc1"

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  debug = false
  quiet = false
  logfile = ""
  hostname = ""
  omit_hostname = false

[[outputs.influxdb]]
  urls = ["http://influxdb.service.consul:8086"] # required
  database = "telegraf" # required
  retention_policy = ""
  write_consistency = "any"
  timeout = "5s"
  username = "telegraf"
  password = "telegraf"

[[inputs.consul]]
  address = "localhost:8500"
  scheme = "http"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false

[[inputs.disk]]
  # mount_points = ["/"]
  # ignore_fs = ["tmpfs", "devtmpfs"]

[[inputs.diskio]]
  # devices = ["sda", "sdb"]
  # skip_serial_number = false

[[inputs.kernel]]
  # no configuration

[[inputs.linux_sysctl_fs]]
  # no configuration

[[inputs.mem]]
  # no configuration

[[inputs.net]]
  interfaces = ["ens*"]

[[inputs.netstat]]
  # no configuration

[[inputs.processes]]
  # no configuration

[[inputs.procstat]]
  pattern = "(consul)"

[[inputs.swap]]
  # no configuration

[[inputs.system]]
  # no configuration

[[inputs.statsd]]
  protocol = "udp"
  service_address = ":8125"
  delete_gauges = true
  delete_counters = true
  delete_sets = true
  delete_timings = true
  percentiles = [90]
  metric_separator = "."
  parse_data_dog_tags = true
  allowed_pending_messages = 10000
  percentile_limit = 1000
EOF

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable telegraf.service
sudo systemctl start telegraf.service
