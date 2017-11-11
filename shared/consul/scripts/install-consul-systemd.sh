#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z ${YUM} ]]; then
  SYSTEMD_DIR="/etc/systemd/system"
  logger "Installing consul systemd service for RHEL/CentOS"
  sudo cp /tmp/consul/init/systemd/consul.service ${SYSTEMD_DIR}
  sudo chmod 0664 ${SYSTEMD_DIR}/consul.service
elif [[ ! -z ${APT_GET} ]]; then
  SYSTEMD_DIR="/lib/systemd/system"
  logger "Installing consul systemd service for Debian/Ubuntu"
  sudo cp /tmp/consul/init/systemd/consul.service ${SYSTEMD_DIR}
  sudo chmod 0664 ${SYSTEMD_DIR}/consul.service
else
  logger "Service not installed due to OS detection failure"
  exit 1;
fi

sudo systemctl enable consul
sudo systemctl start consul

logger "Complete"
