#!/usr/bin/env bash
set -x

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true

##--------------------------------------------------------------------
## Configure Audit Backend

mkdir /home/ubuntu/vault-logs/
sudo chown vault:vault /home/ubuntu/vault-logs/

tee audit-backend-file.json <<EOF
{
  "type": "file",
  "options": {
    "path": "/home/ubuntu/vault-logs/vault-log.txt"
  }
}
EOF

curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @audit-backend-file.json \
    $VAULT_ADDR/v1/sys/audit/file-audit

sudo chmod -R 0777 /home/ubuntu/vault-logs/

##--------------------------------------------------------------------
## Create ACL Policies

# Policy to apply to AppRole token
tee app-1-secret-read.json <<EOF
{"policy":"path \"secret/app-1\" {capabilities = [\"read\", \"list\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app-1-secret-read.json \
    $VAULT_ADDR/v1/sys/policy/app-1-secret-read

##--------------------------------------------------------------------

# Policy to get RoleID
tee app-1-approle-roleid-get.json <<EOF
{"policy":"path \"auth/approle/role/app-1/role-id\" {capabilities = [\"read\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app-1-approle-roleid-get.json \
    $VAULT_ADDR/v1/sys/policy/app-1-approle-roleid-get

##--------------------------------------------------------------------

# Policy to get SecretID
tee app-1-approle-secretid-create.json <<EOF
{"policy":"path \"auth/approle/role/app-1/secret-id\" {capabilities = [\"update\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @app-1-approle-secretid-create.json \
    $VAULT_ADDR/v1/sys/policy/app-1-approle-secretid-create

##--------------------------------------------------------------------

# For Terraform
# See: https://www.terraform.io/docs/providers/vault/index.html#token
tee terraform-token-create.json <<EOF
{"policy":"path \"/auth/token/create\" {capabilities = [\"update\"]}"}
EOF

# Write the policy
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @terraform-token-create.json \
    $VAULT_ADDR/v1/sys/policy/terraform-token-create

##--------------------------------------------------------------------

# List ACL policies
curl \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request LIST \
    $VAULT_ADDR/v1/sys/policy | jq

##--------------------------------------------------------------------
## Enable & Configure AppRole Auth Backend

# AppRole auth backend config
tee approle.json <<EOF
{
  "type": "approle",
  "description": "Demo AppRole auth backend"
}
EOF

# Create the backend
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @approle.json \
    $VAULT_ADDR/v1/sys/auth/approle

# AppRole backend configuration
tee app-1-approle-role.json <<EOF
{
    "role_name": "app-1",
    "bind_secret_id": true,
    "secret_id_ttl": "10m",
    "secret_id_num_uses": "1",
    "token_ttl": "10m",
    "token_max_ttl": "30m",
    "period": 0,
    "policies": [
        "app-1-secret-read"
    ]
}
EOF

# Create the AppRole role
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @app-1-approle-role.json \
    $VAULT_ADDR/v1/auth/approle/role/app-1

# Configure token for RoleID
tee roleid-token-config.json <<EOF
{
  "policies": [
    "app-1-approle-roleid-get",
    "terraform-token-create"
  ],
  "metadata": {
    "user": "chef-demo"
  },
  "ttl": "720h",
  "renewable": true
}
EOF

# Get token
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @roleid-token-config.json \
    $VAULT_ADDR/v1/auth/token/create > roleid-token.json

# Configure token for SecretID
tee secretid-token-config.json <<EOF
{
  "policies": [
    "app-1-approle-secretid-create"
  ],
  "metadata": {
    "user": "chef-demo"
  },
  "ttl": "720h",
  "renewable": true
}
EOF

# Get token
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @secretid-token-config.json \
    $VAULT_ADDR/v1/auth/token/create > secretid-token.json


# Enable kv at secret
curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{ "type": "kv" }' \
    $VAULT_ADDR/v1/sys/mounts/secret

# Write some demo secrets
tee demo-secrets.json <<'EOF'
{
  "username": "app-1-user",
  "password": "my-long-password"
}
EOF

curl \
    --silent \
    --location \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @demo-secrets.json \
    $VAULT_ADDR/v1/secret/app-1

cat roleid-token.json | jq -r .auth.client_token
cat secretid-token.json | jq -r .auth.client_token
