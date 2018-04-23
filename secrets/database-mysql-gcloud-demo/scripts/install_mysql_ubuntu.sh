#!/bin/bash

set -e

cd /tmp

echo "Installing MariaDB MySQL..."
sudo apt-get update -y
sudo apt-get install -y mariadb-server
echo -e "\n[mysqld]\nbind-address=0.0.0.0\nskip-name-resolve=1" | sudo tee -a /etc/mysql/my.cnf

# Start MySQL and set root password
sudo systemctl start mysql
sudo mysqladmin -uroot password 'bananas'

# Load some sample data into an 'employees' database
git clone https://github.com/datacharmer/test_db
cd test_db
sudo mysql -u root -p'bananas' < employees.sql 

# Create our Vault user
sudo mysql -u root -p'bananas' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' IDENTIFIED BY 'vaultpw' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF