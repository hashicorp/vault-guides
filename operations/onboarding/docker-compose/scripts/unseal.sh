#!/bin/bash

# Unseal vault_s1
echo "Unseal vault_s1"
export VAULT_ADDR=http://localhost:8200

export unseal_key=$(cat vault.txt | jq -r '.unseal_keys_b64[0]')
vault operator unseal ${unseal_key}

# Unseal vault_s2
echo "Unseal vault_s2"
export VAULT_ADDR=http://localhost:18200
vault operator unseal ${unseal_key}

# Unseal vault_s3
echo "Unseal vault_s3"
export VAULT_ADDR=http://localhost:28200
vault operator unseal ${unseal_key}

# Reset vault addr and add vault token
export VAULT_ADDR=http://localhost:8200

export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')
vault token lookup
