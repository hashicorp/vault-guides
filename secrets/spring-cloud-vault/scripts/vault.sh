#!/bin/bash

#*****Policy*****

echo 'path "secret/spring-vault-demo" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/application" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/decrypt/order" {
  capabilities = ["update"]
}

path "transit/encrypt/order" {
  capabilities = ["update"]
}

path "database/creds/order" {
  capabilities = ["read"]
}

path "sys/renew/*" {
  capabilities = ["update"]
}' | vault policy-write order -

#*****Postgres Confg*****

#Mount DB backend
vault mount database

#Create the DB connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  allowed_roles="*" \
  connection_url="postgresql://postgres:postgres@localhost:5432/postgres"

#Create the DB order role
vault write database/roles/order \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\"; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

#*****Transit Confg*****

#Mount transit backend
vault mount transit

#Create transit key
vault write -f transit/keys/order
