#!/bin/bash

sudo apt update
sudo apt-get install -y unzip jq 

sudo cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
EOF

cd/tmp
sudo curl ${vault_download_url} -o /tmp/vault.zip

logger "Installing vault"
sudo unzip -o /tmp/vault.zip -d /usr/bin/

nohup /usr/bin/vault server -dev \
  -dev-root-token-id="password" \
  -dev-listen-address="0.0.0.0:8200" 0<&- &>/dev/null &

export VAULT_ADDR=http://127.0.0.1:8200

vault login password

sudo cat << EOF > /tmp/test.policy
path "*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
vault policy write test /tmp/test.policy

vault auth enable azure

vault write auth/azure/config \
  tenant_id=${tenant_id} \
  resource=https://management.azure.com/ \
  client_id=${client_id} \
  client_secret=${client_secret} 

vault write auth/azure/role/dev-role policies="test" \
  bound_subscription_ids="${subscription_id}"

sudo cat << EOF > /tmp/azure_auth.sh
set -v
export VAULT_ADDR="http://127.0.0.1:8200"

vault write auth/azure/login role="dev-role" \
  jwt="$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F'  -H Metadata:true -s | jq -r .access_token)" \
  subscription_id="${subscription_id}" \
  resource_group_name="${resource_group_name}" \
  vm_name="${vm_name}"
EOF

sudo chmod +x /tmp/azure_auth.sh