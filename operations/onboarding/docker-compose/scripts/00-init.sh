#!/bin/bash

# Init and unseal vault_s1
echo "Init and unseal vault_s1"
export VAULT_ADDR=http://localhost:8200
sleep 5
vault operator init -format=json -n 1 -t 1 > vault.txt

export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')

echo "VAULT TOKEN: $VAULT_TOKEN"


export unseal_key=$(cat vault.txt | jq -r '.unseal_keys_b64[0]')
vault operator unseal ${unseal_key}
vault token lookup

# Unseal vault_s2
echo "Unseal vault_s2"
export VAULT_ADDR=http://localhost:18200
vault operator unseal ${unseal_key}

# Unseal vault_s3
echo "Unseal vault_s3"
export VAULT_ADDR=http://localhost:28200
vault operator unseal ${unseal_key}

# Reset vault addr
export VAULT_ADDR=http://localhost:8200

