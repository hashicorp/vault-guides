#!/bin/bash

# This script configures a Postgres Dynamic Database credential database for benchmarking
vault secrets enable database

vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  allowed_roles="*" \
  connection_url="postgresql://{{username}}:{{password}}@db:5432/products?sslmode=disable" \
  username="postgres" \
  password="password"

vault write database/roles/benchmarking \
    db_name=postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="24h" \
    max_ttl="48h"

vault read database/creds/benchmarking

