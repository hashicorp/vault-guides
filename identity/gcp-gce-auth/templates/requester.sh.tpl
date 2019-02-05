#!/bin/bash -v

apt-get update -y

apt-get install curl jq -y

cat <<EOF >> /root/.vault_credentials
function set_vault_credentials {
  VAULT_ADDR=${vault_addr}

  JWT=\$(curl -H "Metadata-Flavor: Google"\
  -G \
  --data-urlencode "audience=$VAULT_ADDR/vault/web"\
  --data-urlencode "format=full" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity")

  check_errors=\$(curl \
    --request POST \
    --data "{\"role\": \"web\", \"jwt\": \"\$JWT\"}" \
    "${vault_addr}/v1/auth/gcp/login" | jq -r ".errors")

  if [ "\$check_errors" == "null" ]
  then
    VAULT_TOKEN=\$(curl \
    --request POST \
    --data "{\"role\": \"web\", \"jwt\": \"\$JWT\"}" \
    "${vault_addr}/v1/auth/gcp/login" | jq -r ".auth.client_token")
  else
    echo "Error from vault: \$check_errors"
    exit 1
  fi

  export VAULT_ADDR
  export VAULT_TOKEN
}

set_vault_credentials

echo 'VAULT_ADDR and VAULT_TOKEN exported to environment'
EOF
