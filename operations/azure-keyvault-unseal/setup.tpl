#!/bin/bash
# TODO remove all sudo commands because this file is run as root.
# NB this file will be executed as root by cloud-init.
# NB to troubleshoot the execution of this file, you can:
#      1. access the virtual machine boot diagnostics pane in the azure portal.
#      2. ssh into the virtual machine and execute:
#           * sudo journalctl
#           * sudo journalctl -u cloud-final
set -euxo pipefail

sudo apt update && sudo apt install -y unzip jq

# TODO create a dedicated account for running vault.
# TODO upgrade to vault 1.5.

VAULT_ZIP="vault.zip"
VAULT_URL="${vault_download_url}"
curl --silent --output /tmp/$${VAULT_ZIP} $${VAULT_URL}
unzip -o /tmp/$${VAULT_ZIP} -d /usr/local/bin/
chmod 0755 /usr/local/bin/vault
chown azureuser:azureuser /usr/local/bin/vault
install -d -m 0750 -o root -g azureuser /etc/vault.d
install -d -m 0750 -o azureuser -g azureuser /opt/vault

export VAULT_ADDR=http://127.0.0.1:8200

cat >/lib/systemd/system/vault.service <<'EOF'
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/bin/vault
ExecStart=/usr/local/bin/vault server -config /etc/vault.d/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=azureuser
Group=azureuser
[Install]
WantedBy=multi-user.target
EOF


cat >/etc/vault.d/config.hcl <<'EOF'
storage "file" {
  path = "/opt/vault"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
seal "azurekeyvault" {
  client_id      = "${client_id}"
  client_secret  = "${client_secret}"
  tenant_id      = "${tenant_id}"
  vault_name     = "${vault_name}"
  key_name       = "${key_name}"
}
ui = true
disable_mlock = true
EOF


sudo chmod 0664 /lib/systemd/system/vault.service
systemctl daemon-reload
sudo chown -R azureuser:azureuser /etc/vault.d
sudo chmod -R 0644 /etc/vault.d/*

cat >/etc/profile.d/vault.sh <<'EOF'
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true
EOF

systemctl enable vault
systemctl start vault

# TODO why isn't this in $HOME?
sudo cat >/tmp/azure_auth.sh <<'EOF'
set -euxo pipefail

# for more information see:
#   * https://www.vaultproject.io/docs/auth/azure
#   * https://www.vaultproject.io/api/auth/azure

export VAULT_ADDR="http://127.0.0.1:8200"

vault auth enable azure

vault write auth/azure/config \
  tenant_id="${tenant_id}" \
  resource="https://management.azure.com/" \
  client_id="${client_id}" \
  client_secret="${client_secret}"

vault write auth/azure/role/dev-role \
  policies="default" \
  bound_subscription_ids="${subscription_id}" \
  bound_resource_groups="${resource_group_name}"

# create a vault login token for the current virtual machine identity (as
# returned by the azure instance metadata service).
# NB use the returned token to login into vault using `vault login`.
# see https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token
vault write auth/azure/login \
  role="dev-role" \
  jwt="$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s | jq -r .access_token)" \
  subscription_id="${subscription_id}" \
  resource_group_name="${resource_group_name}" \
  vm_name="${vm_name}"
EOF

sudo chmod +x /tmp/azure_auth.sh
