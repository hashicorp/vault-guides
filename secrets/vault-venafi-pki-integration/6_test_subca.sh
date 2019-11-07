#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200

# This example should pass based on policy
echo -e "===== Enroll a few certificates from the Vault CA ====="
JSON=$(vault write -format=json subca/issue/web_server \
	common_name="alpha.venafi.example" ip_sans="10.20.30.40" ttl=720h format=pem)
SERIAL_1=$(echo $JSON | sed 's/^.*"serial_number":\s*"\([^"]*\)".*$/\1/')
echo $JSON

# This example should pass based on policy
JSON=$(vault write -format=json subca/issue/web_server \
	common_name="beta.venafi.example" ip_sans="172.16.172.16" ttl=720h format=pem)
SERIAL_2=$(echo $JSON | sed 's/^.*"serial_number":\s*"\([^"]*\)".*$/\1/')
echo $JSON

# This example should pass based on policy
JSON=$(vault write -format=json subca/issue/web_server \
	common_name="delta.venafi.example" ip_sans="192.168.192.168" ttl=720h format=pem)
SERIAL_3=$(echo $JSON | sed 's/^.*"serial_number":\s*"\([^"]*\)".*$/\1/')
echo $JSON

# This example should fail based on policy due to alt_names="delta.venafis.example
JSON=$(vault write -format=json subca/issue/web_server \
	common_name="delta.venafi.example" alt_names="delta.venafis.example" ip_sans="192.168.192.168" ttl=720h format=pem)
SERIAL_4=$(echo $JSON | sed 's/^.*"serial_number":\s*"\([^"]*\)".*$/\1/')
echo $JSON

# List, inspect and revoke certificates
vault list subca/certs

vault write subca/revoke serial_number=$SERIAL_1
vault write subca/revoke serial_number=$SERIAL_2

vault read -field=certificate subca/cert/$SERIAL_3 | openssl x509 -noout -text -certopt no_pubkey,no_sigdump
vault write subca/revoke serial_number=$SERIAL_3
