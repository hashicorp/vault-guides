#!/bin/bash
 
apt-get install --yes ${application}

VAULT_ADDR=http://${vault_addr}:8200
PKCS7=$(curl http://169.254.169.254/latest/dynamic/instance-identity/pkcs7)

echo "{
        \"role\": \"aws-demo-role-ec2\",
        \"pkcs7\": \"$PKCS7\",
        \"nonce\": \"1234\" 
}" > payload.json


VAULT_TOKEN=$(curl \
    --request POST \
    --data @payload.json \
    $VAULT_ADDR/v1/auth/aws/login | jq -r .auth.client_token)

SECRET=$(curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/kv1/aws_demo | jq -r .data.value)

echo "Secret retrieved from Vault: $SECRET"

echo "Secret retrieved from Vault: $SECRET" > /tmp/vault_secret.txt