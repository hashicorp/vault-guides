#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running"

VAULT_HELPER_VERSION="0.1.4"
VAULT_HELPER_ZIP="vault-ssh-helper_${VAULT_HELPER_VERSION}_linux_amd64.zip"
VAULT_HELPER_URL="https://releases.hashicorp.com/vault-ssh-helper/${VAULT_HELPER_VERSION}/vault-ssh-helper_${VAULT_HELPER_VERSION}_linux_amd64.zip"

logger "Downloading Vault SSH Helper version ${VAULT_HELPER_VERSION}"
curl --silent --output /tmp/${VAULT_HELPER_ZIP} ${VAULT_HELPER_URL}

logger "Installing Vault SSH Helper"
cd /tmp
unzip -q $VAULT_HELPER_ZIP >/dev/null
sudo chmod +x vault-ssh-helper
sudo mv vault-ssh-helper /usr/local/bin
sudo chmod 0755 /usr/local/bin/vault-ssh-helper
sudo chown root:root /usr/local/bin/vault-ssh-helper
