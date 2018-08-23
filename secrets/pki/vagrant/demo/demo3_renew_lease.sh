# Wait seconds before automatically running the next command
DEMO_WAIT=1

# Source in default environment variables
. /demo/default_env.sh

# Source in all functions
. /demo/vault_demo_functions.sh 

VAULT_USE_TLS=true
VAULT_ADDR=https://${VAULT_HOST}:${VAULT_PORT}

. /demo/initial_root_token

CERT_BASE=shortttl.${DEMO_DOMAIN}

# We want these to just keep running on their own when wrapped in pe calls
NO_WAIT=true
while true;do
    echo "$(date +%H:%M:%S): Renewing Certificate"
    issue_cert ${CERT_BASE} 60 pki_int_main short-ttl-${ROOT_ROLE}
    sleep 30
done

