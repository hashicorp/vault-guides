#!/bin/bash
# shellcheck disable=SC2005,SC2030,SC2031,SC2174
#
# This script helps manage Vault running in a multi-node cluster
# using the integrated storage (Raft) backend.
#
# Learn Guide: https://learn.hashicorp.com/vault/beta/raft-storage
#
# NOTES:
# - This script is intended only to be used in an educational capacity.
# - This script is not intended to manage a Vault in a production environment.
# - This script supports Linux and macOS
# - Linux support expects the 'ip' command instead of 'ifconfig' command

set -e

demo_home="$(pwd)"
script_name="$(basename "$0")"
os_name="$(uname -s | awk '{print tolower($0)}')"

if [ "$os_name" != "darwin" ] && [ "$os_name" != "linux" ]; then
  >&2 echo "Sorry, this script supports only Linux or macOS operating systems."
  exit 1
fi

function vault_to_network_address {
  local vault_node_name=$1

  case "$vault_node_name" in
    vault_1)
      echo "http://127.0.0.1:8210"
      ;;
    vault_2)
      echo "http://127.0.0.1:8220"
      ;;
    vault_3)
      echo "http://127.0.0.1:8230"
      ;;
  esac
}

# Create a helper function to address the second vault node
function vault_1 {
    (export VAULT_ADDR=http://127.0.0.1:8210 && vault "$@")
}

# Create a helper function to address the third vault node
function vault_2 {
    (export VAULT_ADDR=http://127.0.0.1:8220 && vault "$@")
}

# Create a helper function to address the fourth vault node
function vault_3 {
    (export VAULT_ADDR=http://127.0.0.1:8230 && vault "$@")
}

function stop_vault {
  local vault_node_name=$1

  service_count=$(pgrep -f "$(pwd)"/config-"$vault_node_name" | wc -l | tr -d '[:space:]')

  printf "\n%s" \
    "Found $service_count Vault service(s) matching that name"

  if [ "$service_count" != "0" ] ; then
    printf "\n%s" \
      "[$vault_node_name] stopping" \
      ""

    pkill -f "$(pwd)/config-$vault_node_name"
  fi
}

function stop {
  case "$1" in
    vault_1)
      stop_vault "vault_1"
      ;;
    vault_2)
      stop_vault "vault_2"
      ;;
    vault_3)
      stop_vault "vault_3"
      ;;
    all)
      for vault_node_name in vault_1 vault_2 vault_3 ; do
        stop_vault $vault_node_name
      done
      ;;
    *)
      printf "\n%s" \
        "Usage: $script_name stop [all|vault_1|vault_2|vault_3]" \
        ""
      ;;
    esac
}


function clean {

  for config_file in $demo_home/config-vault_1.hcl $demo_home/config-vault_2.hcl $demo_home/config-vault_3.hcl ; do
    if [[ -f "$config_file" ]] ; then
      printf "\n%s" \
        "Removing configuration file $config_file"

      rm "$config_file"
      printf "\n"
    fi
  done

  for raft_storage in $demo_home/raft-vault_1 $demo_home/raft-vault_2 $demo_home/raft-vault_3 $demo_home/vault-raft-file ; do
    if [[ -d "$raft_storage" ]] ; then
    printf "\n%s" \
        "Removing raft storage file $raft_storage"

      rm -rf "$raft_storage"
    fi
  done

  for key_file in $demo_home/rootToken1 $demo_home/unsealKey1 $demo_home/unsealKey2 ; do
    if [[ -f "$key_file" ]] ; then
      printf "\n%s" \
        "Removing key $key_file"

      rm "$key_file"
    fi
  done

  for token_file in $demo_home/root_token-vault_1 $demo_home/root_token-vault_1 ; do
    if [[ -f "$token_file" ]] ; then
      printf "\n%s" \
        "Removing key $token_file"

      rm "$token_file"
    fi
  done

  for vault_log in $demo_home/vault_1.log $demo_home/vault_2.log $demo_home/vault_3.log ; do
    if [[ -f "$vault_log" ]] ; then
      printf "\n%s" \
        "Removing log file $vault_log"

      rm "$vault_log"
    fi
  done

  # to successfully demo again later, previous VAULT_TOKEN cannot be present
  unset VAULT_TOKEN

  printf "\n%s" \
    "Clean complete" \
    ""
}

function status {
  service_count=$(pgrep -f "$(pwd)"/config | wc -l | tr -d '[:space:]')

  printf "\n%s" \
    "Found $service_count Vault services" \
    ""

  if [[ "$service_count" != 4 ]] ; then
    printf "\n%s" \
    "Unable to find all Vault services" \
    ""
  fi

  printf "\n%s" \
    "[vault_1] status" \
    ""
  vault_1 status || true

  printf "\n%s" \
    "[vault_2] status" \
    ""
  vault_2 status || true

  printf "\n%s" \
    "[vault_3] status" \
    ""
  vault_3 status || true

  sleep 2
}


function update {
  set -aex
  rm -rf "$demo_home"/raft-vault_1
  mkdir -pm 0755 "$demo_home"/raft-vault_1

  local vault_node_name="vault_1"
  printf "\n%s" \
    "[$vault_node_name] Update the config-vault_1.hcl with ha_storage" \
    ""

  tee "$demo_home"/config-vault_1.hcl 1> /dev/null <<EOF
  ha_storage "raft" {
    path    = "$demo_home/raft-vault_1/"
    node_id = "vault_1"
  }

  storage "file" {
  	path = "$demo_home/vault-raft-file/"
  }

  listener "tcp" {
    address = "127.0.0.1:8210"
    cluster_address = "127.0.0.1:8211"
    tls_disable = true
  }

  disable_mlock = true
  api_addr = "http://127.0.0.1:8210"
  cluster_addr = "http://127.0.0.1:8211"
EOF

  local vault_config_file=$demo_home/config-$vault_node_name.hcl
  local vault_log_file=$demo_home/$vault_node_name.log

  printf "\n%s" \
    "[$vault_node_name] starting Vault server @ $vault_node_name" \
    ""

  VAULT_API_ADDR=http://127.0.0.1:8210 vault server -log-level=trace -config "$vault_config_file" > "$vault_log_file" 2>&1 &
  while ! nc -w 1 localhost 8210 </dev/null; do sleep 1; done

  printf "\n%s" \
    "[vault_1] Unseal and log in to vault_1" \
    ""

  vault_1 operator unseal `cat $demo_home/unsealKey1`

  sleep 10s

  printf "\n%s" \
    "[vault_1] Bootstrap: vault write -f sys/storage/raft/bootstrap" \
    ""

  vault_1 write -f sys/storage/raft/bootstrap

  sleep 5s

  printf "\n%s" \
    "[vault_1] Server status" \
    ""
  vault_1 status
}


function setup_vault_1 {

  set -aex
  # Kill all previous server instances
  ps aux | grep "vault server" | grep -v grep | awk '{print $2}' | xargs kill

  rm -rf "$demo_home"/vault-raft-file
  mkdir -pm 0755 "$demo_home"/vault-raft-file

  printf "\n%s" \
    "[vault_1] Creating configuration" \
    "  - creating $demo_home/config-vault_1.hcl" \
    "  - creating $demo_home/raft-vault_1"

  rm -f config-vault_1.hcl

  tee "$demo_home"/config-vault_1.hcl 1> /dev/null <<EOF
  storage "file" {
  	path = "$demo_home/vault-raft-file/"
  }

  listener "tcp" {
    address = "127.0.0.1:8210"
    cluster_address = "127.0.0.1:8211"
    tls_disable = true
  }

  disable_mlock = true
  api_addr = "http://127.0.0.1:8210"
  cluster_addr = "http://127.0.0.1:8211"
EOF

  local vault_node_name="vault_1"
  local vault_config_file=$demo_home/config-$vault_node_name.hcl
  local vault_log_file=$demo_home/$vault_node_name.log

  printf "\n%s" \
    "[$vault_node_name] starting Vault server @ $vault_node_name" \
    ""

  VAULT_API_ADDR=http://127.0.0.1:8210 vault server -log-level=trace -config "$vault_config_file" > "$vault_log_file" 2>&1 &
  while ! nc -w 1 localhost 8210 </dev/null; do sleep 1; done

  printf "\n%s" \
    "[vault_1] initializing and capturing the recovery key and root token" \
    ""

  # Initialize the second node and capture its recovery keys and root token
  initResult=$(vault_1 operator init -format=json -key-shares=1 -key-threshold=1)

  unsealKey1=$(echo -n $initResult | jq -r '.unseal_keys_b64[0]')
  rootToken1=$(echo -n $initResult | jq -r '.root_token')
  echo -n $unsealKey1 > $demo_home/unsealKey1
  echo -n $rootToken1 > $demo_home/rootToken1

  vault_1 operator unseal `cat $demo_home/unsealKey1`

  sleep 2s

  vault_1 login `cat $demo_home/rootToken1`

  printf "\n%s" \
    "[vault_1] logging in and enabling the KV secrets engine" \
    ""
  sleep 2s # Added for human readability

  vault_1 secrets enable -path=kv kv-v2

  printf "\n%s" \
    "[vault_1] storing secret 'kv/apikey' for testing" \
    ""

  vault_1 kv put kv/apikey webapp=ABB39KKPTWOR832JGNLS02
  vault_1 kv get kv/apikey
}

function setup_vault_2 {
  set -aex

  printf "\n%s" \
    "[vault_2] Creating configuration" \
    "  - creating $demo_home/config-vault_2.hcl" \
    "  - creating $demo_home/raft-vault_2"

  rm -f config-vault_2.hcl
  rm -rf "$demo_home"/raft-vault_2
  mkdir -pm 0755 "$demo_home"/raft-vault_2

  tee "$demo_home"/config-vault_2.hcl 1> /dev/null <<EOF
  ha_storage "raft" {
    path    = "$demo_home/raft-vault_2/"
    node_id = "vault_2"
  }

  storage "file" {
    path = "$demo_home/vault-raft-file/"
  }

  listener "tcp" {
    address = "127.0.0.1:8220"
    cluster_address = "127.0.0.1:8221"
    tls_disable = true
  }

  disable_mlock = true
  api_addr = "http://127.0.0.1:8220"
  cluster_addr = "http://127.0.0.1:8221"
EOF

  local vault_node_name="vault_2"
  local vault_config_file=$demo_home/config-$vault_node_name.hcl
  local vault_log_file=$demo_home/$vault_node_name.log

  printf "\n%s" \
    "[$vault_node_name] starting Vault server @ $vault_node_name" \
    ""

  VAULT_API_ADDR=http://127.0.0.1:8220 vault server -log-level=trace -config "$vault_config_file" > "$vault_log_file" 2>&1 &
  while ! nc -w 1 localhost 8220 </dev/null; do sleep 1; done
  sleep 2s

  printf "\n%s" \
    "[$vault_node_name] Unseal $vault_node_name" \
    ""
  vault_2 operator unseal `cat $demo_home/unsealKey1`

  sleep 1s

  printf "\n%s" \
    "[$vault_node_name] Join the raft cluster" \
    ""
  vault_2 operator raft join

  sleep 5s

  vault_2 login `cat $demo_home/rootToken1`

  printf "\n%s" \
    "[$vault_node_name] List the raft cluster members" \
    ""
  vault_2 operator raft list-peers

  printf "\n%s" \
    "[$vault_node_name] Vault status" \
    ""
  vault_2 status
}

function setup_vault_3 {
  set -aex

  printf "\n%s" \
    "[vault_3] Creating configuration" \
    "  - creating $demo_home/config-vault_3.hcl" \
    "  - creating $demo_home/raft-vault_3"

  rm -f config-vault_3.hcl
  rm -rf "$demo_home"/raft-vault_3
  mkdir -pm 0755 "$demo_home"/raft-vault_3

  tee "$demo_home"/config-vault_3.hcl 1> /dev/null <<EOF
  ha_storage "raft" {
    path    = "$demo_home/raft-vault_3/"
    node_id = "vault_3"
  }

  storage "file" {
    path = "$demo_home/vault-raft-file/"
  }

  listener "tcp" {
    address = "127.0.0.1:8230"
    cluster_address = "127.0.0.1:8231"
    tls_disable = true
  }

  disable_mlock = true
  api_addr = "http://127.0.0.1:8230"
  cluster_addr = "http://127.0.0.1:8231"
EOF
  printf "\n"

  local vault_node_name="vault_3"
  local vault_config_file=$demo_home/config-$vault_node_name.hcl
  local vault_log_file=$demo_home/$vault_node_name.log

  printf "\n%s" \
    "[$vault_node_name] starting Vault server @ $vault_node_name" \
    ""

  VAULT_API_ADDR=http://127.0.0.1:8230 vault server -log-level=trace -config "$vault_config_file" > "$vault_log_file" 2>&1 &
  while ! nc -w 1 localhost 8230 </dev/null; do sleep 1; done
  sleep 2s

  printf "\n%s" \
    "[$vault_node_name] Unseal $vault_node_name" \
    ""
  vault_3 operator unseal `cat $demo_home/unsealKey1`

  sleep 1s

  printf "\n%s" \
    "[$vault_node_name] Join the raft cluster" \
    ""
  vault_3 operator raft join

  sleep 5s

  vault_3 login `cat $demo_home/rootToken1`

  printf "\n%s" \
    "[$vault_node_name] List the raft cluster members" \
    ""
  vault_3 operator raft list-peers

  printf "\n%s" \
    "[$vault_node_name] Vault status" \
    ""
  vault_3 status
}


function setup {
  case "$1" in
    vault_1)
      setup_vault_1
      ;;
    vault_2)
      setup_vault_2
      ;;
    vault_3)
      setup_vault_3
      ;;
    all)
      for vault_setup_function in setup_vault_1 setup_vault_2 setup_vault_3 ; do
        $vault_setup_function
      done
      ;;
    *)
      printf "\n%s" \
      "Sets up resources for the cluster" \
      "Usage: $script_name setup [all|vault_1|vault_1|vault_2|vault_3]" \
      ""
      ;;
  esac
}

case "$1" in
  update)
    update
    ;;
  setup)
    shift ;
    setup "$@"
    ;;
  vault_1)
    shift ;
    vault_1 "$@"
    ;;
  vault_2)
    shift ;
    vault_2 "$@"
    ;;
  vault_3)
    shift ;
    vault_3 "$@"
    ;;
  status)
    status
    ;;
  start)
    shift ;
    start "$@"
    ;;
  stop)
    shift ;
    stop "$@"
    ;;
  clean)
    stop all
    clean
    ;;
  *)
    printf "\n%s" \
      "This script helps manages a Vault HA cluster with raft storage." \
      "View the README.md the complete guide at https://learn.hashicorp.com/vault/beta/raft-storage" \
      "" \
      "Usage: $script_name [update|setup|status|stop|clean|vault_1|vault_2|vault_3]" \
      ""
    ;;
esac
