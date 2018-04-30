#!/usr/bin/env bash

## mariadb setup
sudo yum install -y mariadb-server
sudo systemctl start mariadb
mysqladmin -u root password R00tPassword

mysql -u root -p'R00tPassword' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'127.0.0.1' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
# Authenticate to Vault
vault auth password

# Mount database backend
vault mount database

# Configure MySQL connection
vault write database/config/mysql \
    plugin_name=mysql-legacy-database-plugin \
    connection_url="vaultadmin:vaultadminpassword@tcp(127.0.0.1:3306)/" \
    allowed_roles="readonly"

# Create MySQL readonly role
vault write database/roles/readonly \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="30m" \
    max_ttl="24h"

# Read a set of credentials from the role
vault read database/creds/readonly

# validate the new user exists in the database
mysql -u root -p'R00tPassword' -e "select user from mysql.user;"

# Revoke the user via the lease ID and verify the user has been deleted from the database
vault revoke database/creds/readonly/919fed1c-e6c1-ba0a-9edc-cba5ce58cdc3