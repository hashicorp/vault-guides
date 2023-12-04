#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


## mariadb setup
sudo yum install -y mariadb-server
sudo systemctl start mariadb
mysqladmin -u root password R00tPassword

mysql -u root -p'R00tPassword' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'127.0.0.1' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF