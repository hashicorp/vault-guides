#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  FILENAME="install-consul-template.sh"
  echo "$DT $FILENAME: $1"
}

logger "Running"

CONSUL_TEMPLATE_VERSION=${VERSION:-"0.19.4"}
CONSUL_TEMPLATE_ZIP="consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip"
CONSUL_TEMPLATE_URL=${URL:-"https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/${CONSUL_TEMPLATE_ZIP}"}
CONSUL_TEMPLATE_USER=${USER:-"consul-template"}
CONSUL_TEMPLATE_GROUP=${GROUP:-"consul-template"}
CONFIG_DIR="/etc/consul-template.d"
DATA_DIR="/opt/consul-template/data"
DOWNLOAD_DIR="/tmp"

logger "Downloading consul-template ${CONSUL_TEMPLATE_VERSION}"
curl --silent --output ${DOWNLOAD_DIR}/${CONSUL_TEMPLATE_ZIP} ${CONSUL_TEMPLATE_URL}

logger "Installing consul-template"
sudo unzip -o ${DOWNLOAD_DIR}/${CONSUL_TEMPLATE_ZIP} -d /usr/local/bin/
sudo chmod 0755 /usr/local/bin/consul-template
sudo chown ${CONSUL_TEMPLATE_USER}:${CONSUL_TEMPLATE_GROUP} /usr/local/bin/consul-template

logger "/usr/local/bin/consul-template --version: $(/usr/local/bin/consul-template --version)"

logger "Configuring consul-template"
sudo mkdir -pm 0755 ${CONFIG_DIR} ${DATA_DIR}
sudo chown -R ${CONSUL_TEMPLATE_USER}:${CONSUL_TEMPLATE_GROUP} ${CONFIG_DIR} ${DATA_DIR}
sudo chmod -R 0644 ${CONFIG_DIR}/*

logger "Complete"
