# These are all the defaults for any environment variables below.  Setting environment variables before accessing this set of defaults will override anything set here.
DEFAULT_ROOT_DOMAIN=hashidemos.com

# Software versions.   These are probably the only values that should change over time
DEFAULT_VAULT_VERSION=0.10.1
DEFAULT_CONSUL_VERSION=1.0.6
DEFAULT_CONSUL_TEMPLATE_VERSION=0.19.4

DEFAULT_ROOT_PKI_PATH=pki_root
DEFAULT_VAULT_PORT=8200
DEFAULT_ROOT_CERT_TTL=87648h
DEFAULT_INTERMEDIATE_CA_PATH=pki_int_main
DEFAULT_INTERMEDIATE_CERT_TTL=43824h
# Make sure token TTLs are longer than cert TTLs so you don't have the expiring token kill the lease on the cert before you expect it to.
DEFAULT_TOKEN_TTL=120s
DEFAULT_LOCAL_MOUNT=/var/tmp
DEFAULT_DOCKER_MOUNT=/var/tmp/docker

ROOT_PKI_PATH=${ROOT_PKI_PATH:-$DEFAULT_ROOT_PKI_PATH}
ROOT_DOMAIN=${ROOT_DOMAIN:-$DEFAULT_ROOT_DOMAIN}
DEMO_DOMAIN=dev.${ROOT_DOMAIN}

VAULT_DOCKER=vault
VAULT_VERSION=${VAULT_VERSION:-$DEFAULT_VAULT_VERSION}
VAULT_IMAGE=${VAULT_DOCKER}:${VAULT_VERSION}
VAULT_HOST=vault1.${DEMO_DOMAIN}
VAULT_PORT=${VAULT_PORT:-$DEFAULT_VAULT_PORT}

CONSUL_DOCKER=consul
CONSUL_VERSION=${CONSUL_VERSION:-$DEFAULT_CONSUL_VERSION}
CONSUL_IMAGE=${CONSUL_DOCKER}:${CONSUL_VERSION}
CONSUL_HOST=consul1.${DEMO_DOMAIN}

CONSUL_TEMPLATE_VERSION=${CONSUL_TEMPLATE_VERSION:-$DEFAULT_CONSUL_TEMPLATE_VERSION}
# Fixing the arch because this is probably always going to run on a fixed platform in a Vagrant
CONSUL_TEMPLATE_BIN="consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.tgz"
CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/${CONSUL_TEMPLATE_BIN}"

# Root CA Certs can most likely be long-lived certs.  Set for 10 years
ROOT_CERT_TTL=${ROOT_CERT_TTL:-$DEFAULT_ROOT_CERT_TTL}
ROOT_ROLE=${ROOT_DOMAIN/./-}

# Default PKI Intermediate Path
INTERMEDIATE_CA_PATH=${INTERMEDIATE_CA_PATH:-$DEFAULT_INTERMEDIATE_CA_PATH}
# Intermediate certs can also be longer lived. Set for 5 years.
INTERMEDIATE_CERT_TTL=${INTERMEDIATE_CERT_TTL:-$DEFAULT_INTERMEDIATE_CERT_TTL}  


LOCAL_MOUNT=${LOCAL_MOUNT:-$DEFAULT_LOCAL_MOUNT}
DOCKER_MOUNT=${DOCKER_MOUNT:-$DEFAULT_DOCKER_MOUNT}

# Local file used to store parameters. Typically used for curl commands payload
# DO NOT STORE LONG TERM DATA HERE!
# This file will get overwritten by any process needing to store input parameters.
INPUT_PARAMS=input-params.json
# Local fs version
LOCAL_INPUT_PARAMS=${LOCAL_MOUNT}/${INPUT_PARAMS}
# Docker fs version (if needed to be read in by the local process)
DOCKER_INPUT_PARAMS=${DOCKER_MOUNT}/${INPUT_PARAMS}
