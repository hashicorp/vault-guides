export VAULT_ADDR=http://127.0.0.1:8200
export API_KEY="<your api key here>"
export VC_ZONE="<your zone here>"
export ALLOWED_DOMAINS="<your allowed domains here>"

# Enable the secrets backend for the venafi-pki-backend plugin:
vault secrets enable -path=venafi-pki -plugin-name=venafi-pki-backend plugin

# Create a PKI role for the venafi-pki backend:
vault write venafi-pki/roles/cloud-backend \
 apikey="$API_KEY" \
 zone="$VC_ZONE" \
 generate_lease=true store_by_cn=true store_pkey=true store_by_serial=true ttl=1h max_ttl=1h \
 allowed_domains="$ALLOWED_DOMAINS" \
 allow_subdomains=true


