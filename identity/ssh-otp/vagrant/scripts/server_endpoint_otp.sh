#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

if [ ! -d /etc/vault-ssh-helper.d ]; then
  sudo mkdir /etc/vault-ssh-helper.d
fi

logger "Configure PAM with Vault SSH helper"
sudo cp /vagrant/config/config.hcl  /etc/vault-ssh-helper.d/config.hcl
sudo cp /vagrant/config/sshd /etc/pam.d/sshd
sudo cp /vagrant/config/sshd_config /etc/ssh/sshd_config

sudo systemctl restart sshd
