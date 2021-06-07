#!/bin/bash

# Docker compose IP address fix
./api_addr.sh

# Init vault_s1
echo "Init and unseal vault_s1"
export VAULT_ADDR=http://localhost:8200
sleep 5
vault operator init -format=json -n 1 -t 1 > vault.txt

export VAULT_TOKEN=$(cat vault.txt | jq -r '.root_token')
echo "Root VAULT TOKEN is: $VAULT_TOKEN"

# Unseal all nodes
./unseal.sh

# Setup Database benchmarking
./benchmark.sh

echo "*** Please Run: export VAULT_TOKEN=${VAULT_TOKEN}"