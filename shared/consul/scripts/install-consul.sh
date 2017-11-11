#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

CONSUL_VERSION="${VERSION}"
CONSUL_ZIP="consul_${CONSUL_VERSION}_linux_amd64.zip"
CONSUL_URL=${URL:-"https://releases.hashicorp.com/consul/${CONSUL_VERSION}/${CONSUL_ZIP}"}

logger "Downloading consul ${CONSUL_VERSION}"
curl --silent --output /tmp/${CONSUL_ZIP} ${CONSUL_URL}

logger "Installing consul"
sudo unzip -o /tmp/${CONSUL_ZIP} -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/consul
sudo chown consul:consul /usr/local/bin/consul
sudo mkdir -pm 0755 /etc/consul.d
sudo mkdir -pm 0755 /opt/consul/data

logger "/usr/local/bin/consul --version: $(/usr/local/bin/consul --version)"

logger "Configuring consul ${CONSUL_VERSION}"
sudo cp /tmp/consul/config/* /etc/consul.d/
sudo chown -R consul:consul /etc/consul.d /opt/consul
sudo chmod -R 0644 /etc/consul.d/*

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z ${YUM} ]]; then
  logger "Installing dnsmasq"
  sudo yum install -q -y dnsmasq
elif [[ ! -z ${APT_GET} ]]; then
  logger "Installing dnsmasq"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y dnsmasq-base dnsmasq
else
  logger "Dnsmasq not installed due to OS detection failure"
  exit 1;
fi

logger "Configuring dnsmasq to forward .consul requests to consul port 8600"
sudo sh -c 'echo "server=/consul/127.0.0.1#8600" >> /etc/dnsmasq.d/consul'
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

logger "Complete"
