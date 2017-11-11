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
  logger "Performing updates and installing prerequisites"
  sudo yum check-update
  sudo yum install -q -y gcc libffi-devel python-devel openssl-devel python-pip
  sudo pip install azure-cli
elif [[ ! -z ${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Performing updates and installing prerequisites"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y libssl-dev libffi-dev python-dev build-essential python-pip
  sudo pip install azure-cli
else
  logger "Prerequisites not installed due to OS detection failure"
  exit 1;
fi

logger "Complete"
