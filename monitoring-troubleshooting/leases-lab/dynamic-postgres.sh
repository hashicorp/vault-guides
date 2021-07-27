#!/bin/bash

# This script demonstrates Vault with the PostgreSQL secrets engine.
# It simulates a condition where leases cannot be revoked by Vault
# because the PostgreSQL server is unreachable at time of revocation.
#
# Dependencies: vault, docker, jq, nc

# Expects VAULT_ADDR to point to a Vault server and
# VAULT_TOKEN to be a root token for it.

# Caution: Script will kill any docker container named "learn-postgres".

set -e

POSTGRES_PASSWORD=rootpass
POSTGRES_USER=sa
PGURLREST="10.42.74.200:5432/postgres?sslmode=disable"
PGCONNURL="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$PGURLREST"
TTL_SECONDS=10

echo "Start PostgreSQL container."
docker rm -f learn-postgres > /dev/null 2>&1

docker run \
    --name learn-postgres \
    --network learn-vault \
    --ip 10.42.74.200 \
    --detach \
    --rm \
    -e "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" \
    -e "POSTGRES_USER=$POSTGRES_USER" \
    postgres

function dpsql() {
  docker run --rm --net learn-vault postgres psql "$@"
}

while ! dpsql "$PGCONNURL" -c "select 1" >/dev/null 2>&1; do sleep 1; echo -n .; done; echo

echo "Configure PostgreSQL secrets engine."
vault secrets enable database || true

vault write database/config/my-postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="db-dba" \
    connection_url="postgresql://{{username}}:{{password}}@$PGURLREST" \
    username="$POSTGRES_USER" \
    password="$POSTGRES_PASSWORD"

vault write database/roles/db-dba \
    db_name="my-postgresql" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH SUPERUSER LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
    revocation_statements="ALTER ROLE \"{{name}}\" NOLOGIN;" \
    renew_statements="ALTER ROLE \"{{name}}\" PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
    default_ttl="$TTL_SECONDS" \
    max_ttl="24h"

vault policy write db-dba <(cat - <<EOF
  path "database/creds/db-dba" {
    capabilities = ["read"]
  }
EOF
)

DBA_TOKEN=$(vault token create -policy=db-dba -period=1m -field=token)

echo "Create PostgreSQL dynamic credential using DBA token."
vault read database/creds/db-dba > /dev/null 2>&1
echo Complete.
