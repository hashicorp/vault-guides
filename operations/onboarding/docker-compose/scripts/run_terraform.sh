#!/bin/bash

export VAULT_ADDR=http://localhost:8200
# This exports VAULT_ADDR and VAULT_TOKEN based on initialization output in vault.txt
export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')

cd ../../terraform
terraform init
sleep 5
terraform apply --auto-approve
