export VAULT_ADDR=http://127.0.0.1:8200

# Enroll a certificate on Venafi Platform
# Be sure to modify the common_name and alt_names as desired
vault write venafi-pki/issue/cloud-backend common_name="test.example.com" alt_names="test-12.example.com,test-2.example.com"
