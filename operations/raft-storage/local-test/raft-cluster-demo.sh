#!/bin/bash

printf "\n%s" \
  "This script manages a Vault cluster to demonstrate the raft storage." \
  "Read the complete guide at https://learn.hashicorp.com/vault/beta/raft-storage" \
  "" \
  ""

set -e

DEMO_HOME=$(pwd)
script_name=`basename "$0"`

function setup() {
  printf "\n%s" \
    "Each node in the Vault cluster requires:" \
    " - a configuration file" \
    " - local loopback address" \
    " - a directory to store the contents of the Raft storage." \
    ""

  printf "\n%s" \
    "These following local loopback addresses will be added:" \
    "  127.0.0.2, 127.0.0.3, and 127.0.0.4" \
    "The configuration files and raft storage files will be generated in the" \
    "following directory:" \
    "" \
    "  $DEMO_HOME"

  printf "\n\n"

  read -p "Continue with execution [Yy]? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      printf "\n%s" \
        "To change this directory set the environment variable \$DEMO_HOME when executing the script." \
        "  DEMO_HOME ./$script_name" \
        ""
        exit 1
  fi

  printf "\n%s" \
   "Cleaning up existing configurations and raft storage." \
   ""

  rm -rf config-vault1.hcl config-vault2.hcl config-vault3.hcl config-vault4.hcl
  rm -rf $DEMO_HOME/vault-raft/ $DEMO_HOME/vault-raft2/ $DEMO_HOME/vault-raft3/ $DEMO_HOME/vault-raft4/
  mkdir -pm 0755 $DEMO_HOME/vault-raft $DEMO_HOME/vault-raft2 $DEMO_HOME/vault-raft3 $DEMO_HOME/vault-raft4/

  printf "Created configuration for first vault node."

  tee $DEMO_HOME/config-vault1.hcl <<EOF
  storage "inmem" {}
  listener "tcp" {
    address = "127.0.0.1:8200"
    tls_disable = true
  }
EOF

  printf "\n%s" \
   "Created configuration for second vault node." \
   ""

  tee $DEMO_HOME/config-vault2.hcl <<EOF
  storage "raft" {
    path    = "$DEMO_HOME/vault-raft/"
    node_id = "node2"
  }
  listener "tcp" {
    address = "127.0.0.2:8200"
    cluster_address = "127.0.0.2:8201"
    tls_disable = true
  }
  seal "transit" {
    address            = "http://127.0.0.1:8200"
    # token is read from VAULT_TOKEN env
    # token              = ""
    disable_renewal    = "false"

    // Key configuration
    key_name           = "unseal_key"
    mount_path         = "transit/"
  }
  disable_mlock = true
  cluster_addr = "http://127.0.0.2:8201"
EOF

  printf "\n%s" \
    "Enabling local loopback on 127.0.0.2 (requires sudo)" \
    ""

  sudo ifconfig lo0 alias 127.0.0.2

  printf "\n%s" \
   "Created configuration for third vault node." \
   ""

  tee $DEMO_HOME/config-vault3.hcl <<EOF
  storage "raft" {
    path    = "$DEMO_HOME/vault-raft2/"
    node_id = "node3"
  }
  listener "tcp" {
    address = "127.0.0.3:8200"
    cluster_address = "127.0.0.3:8201"
    tls_disable = true
  }
  seal "transit" {
    address            = "http://127.0.0.1:8200"
    # token is read from VAULT_TOKEN env
    # token              = ""
    disable_renewal    = "false"

    // Key configuration
    key_name           = "unseal_key"
    mount_path         = "transit/"
  }
  disable_mlock = true
  cluster_addr = "http://127.0.0.3:8201"
EOF

  printf "\n%s" \
    "Enabling local loopback on 127.0.0.3 (requires sudo)" \
    ""

  sudo ifconfig lo0 alias 127.0.0.3

  printf "\n%s" \
   "Created configuration for fourth vault node." \
   ""

  tee $DEMO_HOME/config-vault4.hcl <<EOF
  storage "raft" {
    path    = "$DEMO_HOME/vault-raft3/"
    node_id = "node4"
  }
  listener "tcp" {
    address = "127.0.0.4:8200"
    cluster_address = "127.0.0.4:8201"
    tls_disable = true
  }
  seal "transit" {
    address            = "http://127.0.0.1:8200"
    # token is read from VAULT_TOKEN env
    # token              = ""
    disable_renewal    = "false"

    // Key configuration
    key_name           = "unseal_key"
    mount_path         = "transit/"
  }
  disable_mlock = true
  cluster_addr = "http://127.0.0.4:8201"
EOF

  printf "\n%s" \
    "Enabling local loopback on 127.0.0.4 (requires sudo)" \
    ""

  sudo ifconfig lo0 alias 127.0.0.4

  printf "\n"

}

# Create a helper function to address the first vault node
function vault_1() {
    (export VAULT_ADDR=http://127.0.0.1:8200 && vault $@)
}

# Create a helper function to address the second vault node
function vault_2() {
    (export VAULT_ADDR=http://127.0.0.2:8200 && vault $@)
}

# Create a helper function to address the third vault node
function vault_3() {
    (export VAULT_ADDR=http://127.0.0.3:8200 && vault $@)
}

# Create a helper function to address the fourth vault node
function vault_4() {
    (export VAULT_ADDR=http://127.0.0.4:8200 && vault $@)
}

function start() {

  printf "\n%s" \
    "[vault-1] starting the node" \
    ""

  VAULT_API_ADDR=http://127.0.0.1:8200 vault server -log-level=trace -config $DEMO_HOME/config-vault1.hcl > $DEMO_HOME/vault1.log 2>&1 &
  sleep 5s

  printf "\n%s" \
    "[vault-1] initializing and capturing the unseal key and root token" \
    ""
  sleep 2s # Added for human readability

  INIT_RESPONSE=$(vault_1 operator init -format=json -key-shares 1 -key-threshold 1)

  UNSEAL_KEY=$(echo $INIT_RESPONSE | jq -r .unseal_keys_b64[0])
  VAULT_TOKEN=$(echo $INIT_RESPONSE | jq -r .root_token)

  printf "\n%s" \
    "[vault-1] Unseal key: $UNSEAL_KEY" \
    "[vault-1] Root token: $VAULT_TOKEN" \
    ""

  printf "\n%s" \
    "[vault-1] unsealing and logging in" \
    ""
  sleep 2s # Added for human readability

  vault_1 operator unseal $UNSEAL_KEY
  vault_1 login $VAULT_TOKEN

  printf "\n%s" \
    "[vault-1] enabling the transit secret engine and storing key to enable remaining nodes to join the cluster" \
    ""
  sleep 5s # Added for human readability

  vault_1 secrets enable transit
  vault_1 write -f transit/keys/unseal_key

  printf "\n%s" \
    "Starting Vault nodes [vault-2], [vault-3] and [vault-4]" \
    ""
  sleep 2s # Added for human readability

  # Start the second, third, and fourth nodes.

  VAULT_TOKEN=$VAULT_TOKEN VAULT_API_ADDR=http://127.0.0.2:8200 vault server -log-level=trace -config $DEMO_HOME/config-vault2.hcl > $DEMO_HOME/vault2.log 2>&1 &
  VAULT_TOKEN=$VAULT_TOKEN VAULT_API_ADDR=http://127.0.0.3:8200 vault server -log-level=trace -config $DEMO_HOME/config-vault3.hcl > $DEMO_HOME/vault3.log 2>&1 &
  VAULT_TOKEN=$VAULT_TOKEN VAULT_API_ADDR=http://127.0.0.4:8200 vault server -log-level=trace -config $DEMO_HOME/config-vault4.hcl > $DEMO_HOME/vault4.log 2>&1 &

  sleep 5s

  printf "\n%s" \
    "[vault-2] initializing and capturing the unseal key and root token" \
    ""
  sleep 2s # Added for human readability

  # Initialize the second node and capture its unseal key and root token
  INIT_RESPONSE2=$(vault_2 operator init -format=json -key-shares 1 -key-threshold 1)

  VAULT_TOKEN2=$(echo $INIT_RESPONSE2 | jq -r .root_token)

  printf "\n%s" \
    "[vault-2] Root token: $VAULT_TOKEN2" \
    ""

  printf "\n%s" \
    "[vault-2] waiting to join Vault cluster (15 seconds)" \
    ""

  sleep 15s

  printf "\n%s" \
    "[vault-2] logging in and enabling the KV secrets engine" \
    ""
  sleep 2s # Added for human readability

  vault_2 login $VAULT_TOKEN2
  vault_2 secrets enable -path=kv kv-v2
  sleep 2s

  printf "\n%s" \
    "[vault-2] storing secret 'kv/apikey' to demonstrate snapshot and recovery methods" \
    ""
  sleep 2s # Added for human readability

  vault_2 kv put kv/apikey webapp=ABB39KKPTWOR832JGNLS02
  vault_2 kv get kv/apikey
}

function stop() {
  service_count=$(pgrep -f $(pwd)/config | wc -l | tr -d '[:space:]')

  printf "\n%s" \
    "Found $service_count Vault services" \
    ""

  if [ $service_count != "0" ] ; then
    printf "\n%s" \
      "Stopping $service_count Vault services" \
      ""

    pkill -f $(pwd)/config
  fi
}

function loopback_exists_at_address() {
  echo $(ifconfig lo0 | grep $1 || true) | tr -d '[:space:]'
}

function clean() {

  printf "\n%s" \
    "Each node in the Vault cluster required:" \
    " - local loopback address" \
    " - a configuration file" \
    " - a directory to store the contents of the Raft storage." \
    ""

  for loopback_address in "127.0.0.2" "127.0.0.3" "127.0.0.4" ; do
    loopback_exists=$(loopback_exists_at_address $loopback_address)

    if [[ $loopback_exists != "" ]] ; then
      printf "\n%s" \
        "Removing local loopback address: $loopback_address (sudo required)" \
        ""

      sudo ifconfig lo0 -alias $loopback_address
    fi
  done

  for config_file in config-vault1.hcl config-vault2.hcl config-vault3.hcl config-vault4.hcl ; do
    if [[ -f "$config_file" ]] ; then
      rm $config_file
    fi
  done

  for raft_storage in $DEMO_HOME/vault-raft $DEMO_HOME/vault-raft2 $DEMO_HOME/vault-raft3 $DEMO_HOME/vault-raft4 ; do
    if [[ -d "$raft_storage" ]] ; then
      rm -rf $raft_storage
    fi
  done

  for vault_log in vault1.log vault2.log vault3.log vault4.log ; do
    if [[ -f "$vault_log" ]] ; then
      rm $vault_log
    fi
  done

  printf "\n%s" \
    "Clean complete" \
    ""
}

function status() {
  service_count=$(pgrep -f $(pwd)/config | wc -l | tr -d '[:space:]')

  printf "\n%s" \
    "Found $service_count Vault services" \
    ""

  if [[ "$service_count" != 4 ]] ; then
    printf "\n%s" \
    "Unable to find all Vault services" \
    ""
    exit 1
  fi

  printf "\n%s" \
    "[vault-1] status" \
    ""
  vault_1 status || true

  printf "\n%s" \
    "[vault-2] status" \
    ""
  vault_2 status || true

  printf "\n%s" \
    "[vault-3] status" \
    ""
  vault_3 status || true

  printf "\n%s" \
    "[vault-4] status" \
    ""
  vault_4 status || true

  sleep 2
}

case "$1" in
  setup)
    setup
    ;;
  start)
    start
    ;;
  status)
    status
    ;;
  stop)
    stop
    ;;
  clean)
    stop
    clean
    ;;
  *)
    printf "\n%s" \
    "Usage: $script_name [setup|start|status|stop|clean]" \
    ""
    ;;
esac
