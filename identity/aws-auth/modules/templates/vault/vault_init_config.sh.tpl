#!/bin/bash

# Vault variable defaults
export VERSION="0.10.3"
#export URL=https://releases.hashicorp.com/vault/0.10.3/vault_0.10.3_linux_amd64.zip
export GROUP=vault
export USER=vault
export COMMENT=Vault
export HOME="/srv/vault"
export VAULT_ADDR="http://0.0.0.0:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=root

curl https://raw.githubusercontent.com/hashicorp/guides-configuration/master/shared/scripts/base.sh | bash
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/master/shared/scripts/setup-user.sh | bash

sudo apt-get install unzip
curl https://raw.githubusercontent.com/hashicorp/guides-configuration/master/vault/scripts/install-vault.sh | bash

# Since this is dev mode, Vault starts unsealed. DO NOT USE IN PRODUCTION!
nohup /usr/local/bin/vault server -dev \
  -dev-root-token-id="root" \
  -dev-listen-address="0.0.0.0:8200" &


# Commands to configure Vault AWS auth method

echo "path \"kv1/aws_demo\" { 
    capabilities = [\"create\", \"read\", \"update\", \"delete\"]
    }" | vault policy write aws-demo-policy -

vault auth enable aws

AWS_ACCESS_KEY_ID=${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}

vault write auth/aws/config/client secret_key=$AWS_SECRET_ACCESS_KEY access_key=$AWS_ACCESS_KEY_ID

vault write auth/aws/role/aws-demo-role-account auth_type=ec2 bound_account_id=${aws_account_id} policies=aws-demo-policy 

vault write auth/aws/role/aws-demo-role-ec2 \
    auth_type=ec2 \
    bound_ami_id=ami-2e1ef954 \
    policies=aws-demo-policy \
    max_ttl=500h

vault write auth/aws/role/aws-demo-role-iam \
    auth_type=iam \
    bound_iam_principal_arn=arn:aws:iam::${aws_account_id}:role/${aws_auth_iam_role} \
    policies=aws-demo-policy \
    max_ttl=500h

# Enable secret mount and write secret
vault secrets enable -path=kv1 -version=1 kv

vault write kv1/aws_demo value=ThisTestWasSuccessful!