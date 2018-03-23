#!/bin/bash

[ ! -n "$DEBUG" ] || set -x

set -ue

# the internet says this is better than 'set -e'
function onerr {
    echo 'Cleaning up after error...'
    exit -1
}
trap onerr ERR


VAULT_UNSEAL_KEY=''
VAULT_ROOT_TOKEN=''

: ${VAULT_NODE_COUNT:=3}


function check_deps () {
    for i in kubectl vault http grep tr cut; do
        if ! command -v $i > /dev/null 2>&1 ; then
            echo "Failed to find \'$i\' in PATH\!"
            exit -1
        else
            echo "Found $i in PATH..."
        fi
    done
}


function setup () {
    echo "Waiting for Consul cluster to be online with leader..."
    for i in {1..60}; do
        echo "Attempt $i..."
        if minikube service --url consul-ui; then
            CONSUL_HTTP_ADDR=$(minikube service --url consul-ui)
            if http "${CONSUL_HTTP_ADDR}/v1/status/leader"; then
                break
            fi
        fi
        sleep 5
    done

    echo "Waiting for vault-ui service port to become available..."
    for i in {1..60}; do
        echo "Attempt $i..."
        if minikube service --url vault-ui ; then
            break
        fi
        sleep 5
    done

    VAULT_ADDR="$(minikube service --url vault-ui)" || exit $?
    export VAULT_ADDR="${VAULT_ADDR}"
}


function vault_init () {
    local unseal_key
    local root_token

    set +e
    echo "Waiting for vault-ui service to become available..."
    for i in {1..60}; do
        echo "Attempt $i..."
        http --check-status "${VAULT_ADDR}/v1/sys/seal-status"
        if [ "5" != "$?" ]; then
            break
        else
            echo "http /v1/sys/seal-status exit code: $?"
        fi
        sleep 5
    done
    set -e

    output=$(vault init -key-shares=1 -key-threshold=1)
    unseal_key="$(echo "${output}" | grep 'Unseal Key 1:' | cut -f2 -d':' | tr -d '[:space:]')"
    root_token="$(echo "${output}" | grep 'Initial Root Token:' | cut -f2 -d':' | tr -d '[:space:]')"
    VAULT_UNSEAL_KEY="${unseal_key}"
    VAULT_ROOT_TOKEN="${root_token}"
}


function vault_unseal () {
    local vault_node_count=0

    # Don't proceed until all Vault instances are in Running state..
    for i in {1..60}; do
        vault_node_count=$(kubectl get pods | grep vault- | grep 'Running' | wc -l)
        if [ $vault_node_count -lt $VAULT_NODE_COUNT ]; then
            echo "Wating on Vault nodes in Running state (${vault_node_count} of ${VAULT_NODE_COUNT})..."
        else
            break
        fi
        sleep 5
    done

    for i in $(kubectl get pods --no-headers | grep 'vault-' | cut -f1 -d' '); do
        kubectl exec -ti $i -c vault -- /bin/sh -c "VAULT_ADDR=http://localhost:8200 vault unseal ${VAULT_UNSEAL_KEY}"
    done

    echo ">>> Vault unseal status:"
    for v in `kubectl get pod | grep vault | cut -f1 -d' '` ; do echo ">>> $v"; kubectl exec -ti $v -c vault -- /bin/sh -c 'echo""; VAULT_ADDR=http://localhost:8200 vault status'; done
}


function main () {
    check_deps
    setup
    vault_init
    vault_unseal

    echo ""
    echo "parsed Vault unseal key: ${VAULT_UNSEAL_KEY}"
    echo "parsed Vault initial root token: ${VAULT_ROOT_TOKEN}"
}


main
