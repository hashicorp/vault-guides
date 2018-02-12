#!/bin/bash

echo "[---Begin install-vault-systemd.sh---]"

echo "Run base script"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/shared/scripts/base.sh | bash

echo "Setup Vault user"
export GROUP=vault
export USER=vault
export COMMENT=Vault
export HOME=/srv/vault
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/shared/scripts/setup-user.sh | bash

echo "Install Vault"
export VERSION=${vault_version}
export URL=${vault_url}
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/vault/scripts/install-vault.sh | bash

echo "Install Vault Systemd"
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/f-refactor/vault/scripts/install-vault-systemd.sh | bash

echo "Cleanup install files"
sudo rm -rf /tmp/*
sudo rm -rf /tmp/.git*

echo "[---install-vault-systemd.sh Complete---]"
