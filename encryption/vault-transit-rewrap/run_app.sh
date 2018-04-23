#!/bin/bash

VAULT_TOKEN=$(cat app-token.txt) VAULT_ADDR=$VAULT_ADDR VAULT_TRANSIT_KEY=my_app_key SHOULD_SEED_USERS=true dotnet run

echo ""
echo "#------------------------------------"
echo "# To view the data in the MySQL DB"
echo "#------------------------------------"
echo "  docker exec -it mysql-rewrap mysql -uroot -proot"
echo "    mysql> USE my_app"
echo "    mysql> DESC user_data;"
echo "    mysql> SELECT * FROM user_data WHERE dob LIKE \"vault:v1%\" limit 10;"
echo ""
