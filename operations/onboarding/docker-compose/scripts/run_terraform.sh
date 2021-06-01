#!/bin/bash

export VAULT_ADDR=http://localhost:8200

# If VAULT_TOKEN is empty, this will export VAULT_ADDR and VAULT_TOKEN enviroment variables based on initialization output in vault.txt
if [[ -z ${VAULT_TOKEN} ]]; then 
  export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')
  echo "**Using the Root token for Terraform**"
else
  echo "**Using an Existing token for Terraform, please adjust policy in case of permission errors**"
  vault token lookup
fi

cd ../../terraform
terraform init
sleep 5
terraform apply --auto-approve
