#!/bin/bash

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='some-root-token'

docker-compose up -d --build

sleep 30

vault auth enable approle

vault secrets enable -path='projects-api/database' database
vault secrets enable -path='projects-api/secrets' -version=2 kv

vault kv put projects-api/secrets/static 'password=Testing!123'

vault write projects-api/database/config/projects-database \
	 	plugin_name=mssql-database-plugin \
	 	connection_url='sqlserver://{{username}}:{{password}}@db:1433' \
	 	allowed_roles="projects-api-role" \
	 	username="sa" \
	 	password="Testing!123"

vault write projects-api/database/roles/projects-api-role \
    db_name=projects-database \
    creation_statements="CREATE LOGIN [{{name}}] WITH PASSWORD = '{{password}}';\
				USE HashiCorp;\
				CREATE USER [{{name}}] FOR LOGIN [{{name}}];\
        GRANT SELECT,UPDATE,INSERT,DELETE TO [{{name}}];" \
    default_ttl="2m" \
    max_ttl="5m"

vault policy write projects-api ./projects-role-policy.hcl

vault write auth/approle/role/projects-api-role \
	  role_id="projects-api-role" \
		token_policies="projects-api" \
		token_ttl=1h \
		token_max_ttl=2h \
		secret_id_num_uses=5

echo "projects-api-role" > ProjectApi/vault-agent/role-id
vault write -f -field=secret_id auth/approle/role/projects-api-role/secret-id > ProjectApi/vault-agent/secret-id