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
  logger "RHEL/CentOS system detected"
  logger "Disabling firewall"
  sudo systemctl stop firewalld.service
  sudo systemctl disable firewalld.service
elif [[ ! -z ${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Disabling firewall"
  sudo ufw disable
else
  logger "Prerequisites not installed due to OS detection failure"
  exit 1;
fi

logger "Complete"
