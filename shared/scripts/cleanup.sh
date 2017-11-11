#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

logger "Reset HashiCorp services"
[[ -f "/usr/local/bin/consul" ]] && sudo systemctl stop consul && sudo rm -rf /opt/consul/data/*
[[ -f "/usr/local/bin/nomad" ]] && sudo systemctl stop nomad && sudo rm -rf /opt/nomad/data/*
[[ -f "/usr/local/bin/vault" ]] && sudo systemctl stop vault && sudo rm -rf /opt/vault/data/*

logger "Cleanup install artifacts"
sudo rm -rf /tmp/*

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z ${YUM} ]]; then
  logger "RHEL/CentOS system detected"
  logger "Performing cleanup"
  history -cw
elif [[ ! -z ${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Performing cleanup"
  history -c
else
  logger "Cleanup aborted due to OS detection failure"
  exit 1;
fi

logger "Complete"
