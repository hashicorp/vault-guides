#!/bin/bash

# Disable transit secret engine
vault secrets disable transit

# Delete the app-token.txt file
rm app-token.txt

# Delete the generated /bin directory
rm -r bin

# Delete the generated /obj directory
rm -r obj

echo ""
echo "#---------------------------------------"
echo "# To clear data in the user_data table"
echo "#---------------------------------------"
echo "  docker exec -it mysql-rewrap mysql -uroot -proot"
echo "    mysql> USE my_app"
echo "    mysql> DELETE FROM user_data;"
echo ""
