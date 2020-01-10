#!/bin/bash

#Initialize and unseal Vault

export VAULT_ADDR=http://127.0.0.1:8200

vault status 2>/dev/null

if [ ! $? -eq 0 ]; then
echo -e "===== Initialize the Vault ====="
vault operator init > init.out
cat init.out
fi

UNSEAL_KEY_1=$(grep "Unseal Key 1" init.out | cut -c 15-)
UNSEAL_KEY_2=$(grep "Unseal Key 2" init.out | cut -c 15-)
UNSEAL_KEY_3=$(grep "Unseal Key 3" init.out | cut -c 15-)
UNSEAL_KEY_4=$(grep "Unseal Key 4" init.out | cut -c 15-)
UNSEAL_KEY_5=$(grep "Unseal Key 5" init.out | cut -c 15-)

TOKEN=$(grep "Token" init.out | cut -c 21-)

echo -e "\r\n===== Unseal the Vault ====="
vault operator unseal $UNSEAL_KEY_1
vault operator unseal $UNSEAL_KEY_2
vault operator unseal $UNSEAL_KEY_3

echo -e "\r\n===== Login to the Vault ====="
vault login $TOKEN
