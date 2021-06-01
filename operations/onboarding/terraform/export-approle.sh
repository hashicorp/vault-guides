#!/bin/bash

[[ -z $1 ]] && echo "usage export-approle.sh app_name" && exit 0

echo "Exporting Role ID and Secret ID for app: $1"

export VAULT_ADDR=http://localhost:8200
# This exports VAULT_ADDR and VAULT_TOKEN based on initialization output in vault.txt
export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')

# Export role and secret IDs for apps
export ROLE_ID=$(terraform output role_ids | grep $1 | tr -d '"' | awk '{print $NF}')
echo ${ROLE_ID} > ../docker-compose/vault-agent/$1_role_id
export SECRET_ID=$(terraform output secret_ids | grep $1 | tr -d '"' | awk '{print $NF}')
echo ${SECRET_ID} > ../docker-compose/vault-agent/$1_secret_id