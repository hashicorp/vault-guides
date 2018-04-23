#!/bin/bash

# INITIAL SETUP: RUN ONLY ONCE

# --------
# Step 1
# --------
# Pull the latest mysql container image
docker pull mysql/mysql-server:5.7

# Create a directory for our data (change the following line if running on Windows)
mkdir ~/rewrap-data

# Run the container.  The following command creates a database named 'my_app',
# specifies the root user password as 'root', and adds a user named vault
docker run --name mysql-rewrap -p 3306:3306 -v ~/rewrap-data/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=my_app -e MYSQL_USER=vault -e MYSQL_PASSWORD=vaultpw -d mysql/mysql-server:5.7

# --------
# Step 2
# --------
# VAULT_SKIP_VERIFY=true

echo "Enabling transit secret engine"
vault secrets enable transit

echo "Creating an encryption key, my_app_key"
vault write -f transit/keys/my_app_key

# --------
# Step 3
# --------
echo "Create rewrap example policy"
vault policy write rewrap_example ./rewrap_example.hcl

echo "Create a token for the sample app to use and save it in app-token.txt"
vault token create -policy=rewrap_example -format=json | jq -r ".auth.client_token" > app-token.txt
