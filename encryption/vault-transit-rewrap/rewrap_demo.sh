#!/bin/bash

#---------------
# Step 5
#---------------
echo "---------------------------"
echo " CURRENT key information "
echo "---------------------------"
vault read transit/keys/my_app_key
echo ""

echo "-----------------------------"
echo " Rotate the encryption key "
echo "-----------------------------"
vault write -f transit/keys/my_app_key/rotate
echo ""

echo "--------------------------------------------"
echo " Key information AFTER the key rotation "
echo "--------------------------------------------"
vault read transit/keys/my_app_key
echo ""

echo "=========================================================================="
echo " To set the min_decryption_version, run: "
echo "  vault write transit/keys/my_app_key/config min_decryption_version=3 "
echo "     & "
echo "  vault read transit/keys/my_app_key "
echo "=========================================================================="
echo ""
