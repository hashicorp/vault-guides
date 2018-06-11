# Source in default environment variables
. /demo/default_env.sh

# Source in all functions
. /demo/vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. /demo/initial_root_token

PKI_PATH=pki_int_main
CERT_BASE=shortttl.${DEMO_DOMAIN}
revoke ${PKI_PATH} $(cat /var/tmp/${CERT_BASE}.serial)
