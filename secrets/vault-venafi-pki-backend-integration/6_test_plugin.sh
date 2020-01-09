# Enroll a certificate on Venafi Platform
vault write venafi-pki/issue/tpp-backend common_name="hashicorpvault.se.venafi.com" alt_names="test-1.se.venafi.com,test-2.se.venafi.com"