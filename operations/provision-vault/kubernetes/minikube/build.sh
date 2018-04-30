#!/bin/bash

[ ! -n "$DEBUG" ] || set -x

set -ue

# the internet says this is better than 'set -e'
function onerr {
    echo 'Cleaning up after error...'

    # at the least, restore the old cwd
    popd
    exit -1
}
trap onerr ERR


pushd `pwd` > /dev/null 2>&1
cd "$(dirname $0)"


function check_for_deps () {
    local deps='docker kubectl'
    for dep in $deps; do
        printf "\n>>> Checking for \'${dep}\' in PATH..."
        if [ ! command -pv "${dep}" > /dev/null 2>&1 ]; then
            printf "\n>>>> Failed to find \'${dep}\'!"
        fi
    done
}


function docker_cache_images () {

    printf "\n>>> Building the HashiCorp Enterprise Docker images within minikube...\n"

    printf "\n>>> Switching over to the dockerd running in minikibe..."
    eval $(minikube docker-env)

    printf "\n>>> Building Consul Enterprise Docker image...\n"
    (cd ./static/consul-enterprise && set -x && docker build --rm -t consul-enterprise -f Dockerfile .)

    printf "\n>>> Building Vault Enterprise Docker image...\n"
    (cd ./static/vault-enterprise  && set -x && docker build --rm -t vault-enterprise -f Dockerfile .)

    # docker pull nrvale0/clusterdebug

    printf "\n>>> Here's some information about cache Docker images...\n"
    docker info
    docker images

    # undo the damage done by minikube docker-env
    for i in DOCKER_TLS_VERIFY DOCKER_HOST DOCKER_CERT_PATH DOCKER_API_VERSION; do
        unset i
    done

    printf "\n>>> If you'd like to interact with the minikube dockerd please see the 'minikube docker-env' command.\n"
}


function consul_deploy_on_k8s () {
    printf "\n>>> Setting up Consul on k8s...\n"
    (set -x ; kubectl apply -f consul.yml)
}


function vault_deploy_on_k8s () {
    printf "\n>>> Setting up Vault on k8s...\n"
    (set -x ; kubectl apply -f vault.yml)
}


function main () {
    check_for_deps
    docker_cache_images
    consul_deploy_on_k8s
    vault_deploy_on_k8s
    # configure Vault k8s integration
    # deploy demo app with Vault sidecar and JWT token
    # run tests

    # last thing, let's reset to cwd to wherever we started...
    popd
}

main
