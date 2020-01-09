export TPP_ADDR=https://example.venafi.com/vedsdk
export TPP_USER=serviceaccountuser
export TPP_PASS=serviceaccountpassword
export TPP_ZONE="Certificates\\\\HashiCorp Vault\\\\Internal PKI"
export VAULT_ADDR=http://127.0.0.1:8200

# Enable the secrets engine for the venafi-pki-backend plugin:
vault secrets enable -path=venafi-pki -plugin-name=venafi-pki-backend plugin

# Create a PKI role for the venafi-pki backend:
vault write venafi-pki/roles/tpp-backend \
    tpp_url="$TPP_ADDR" \
    tpp_user="$TPP_USER" \
    tpp_password="$TPP_PASS" \
    zone="$TPP_ZONE" \
    generate_lease=true store_by_cn=true store_pkey=true store_by_serial=true ttl=1h max_ttl=1h \
    allowed_domains=venafi.com \
    allow_subdomains=true


