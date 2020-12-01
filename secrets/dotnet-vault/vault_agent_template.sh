#!/bin/bash

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='some-root-token'

vault write projects-api/database/roles/projects-api-role \
    db_name=projects-database \
    creation_statements="CREATE LOGIN [{{name}}] WITH PASSWORD = '{{password}}';\
				USE HashiCorp;\
				CREATE USER [{{name}}] FOR LOGIN [{{name}}];\
        GRANT SELECT,UPDATE,INSERT,DELETE TO [{{name}}];" \
    default_ttl="2m" \
    max_ttl="5m"

docker-compose -f docker-compose-vault-agent-template.yml up -d