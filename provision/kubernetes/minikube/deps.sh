#!/bin/bash

[ ! -n "$DEBUG" ] || set -x

set -u

# the internet says this is better than 'set -e'
function onerr {
    echo 'Cleaning up after error...'
    popd
    exit -1
}
trap onerr ERR


pushd `pwd` > /dev/null 2>&1
cd "$(dirname $0)"


function check_for_deps () {
    for dep in pidof; do
	if ! command -v "${dep}" > /dev/null 2>&1 ; then
	    printf "\n>>>> Failed to find \'${dep}\'!\n"
	    exit -1
	fi
    done
}


function docker_check () {
    if ! command -v docker > /dev/null 2>&1; then
	printf "\n>>> Failed to find docker binary in path." >&2
	printf "\n>>> Please see https://docker.com to download and install Docker.\n" >&2
	exit -1
    fi

    # Would be nice to check for dockerd process but most OSes other than Linux
    # run it in VM with a bunch of 'clever' shell aliases.
    printf "\n>>> Note: Please ensure Docker is running and available via the 'docker' CLI...\n"
}


function minikube_check () {
    if ! command -v minikube > /dev/null 2>&1; then
	printf "\n>>> Failed to find minikube binary in PATH." >&2
	printf "\n>>> Please see https://kubernetes.io/docs/getting-started-guides/minikube/ for instructions on downloading and installing minikube.\n" >&2
	exit -1
    fi

    if ! minikube status > /dev/null 2>&1 ; then
	printf "\n>>> Failed to find k8s cluster running minikube. You likely need to 'minikube start'.\n" >&2
	exit -1
    fi
}


function kubectl_check () {
    if ! command -v kubectl > /dev/null 2>&1; then
	printf "\n>>> Failed to find kubectl binary in PATH." >&2
	printf "\n>>> Please see https://kubernetes.io/docs/tasks/tools/install-kubectl/ for instructions on downloading andn installing kubectl.\n" >&2
	exit -1
    fi
}


function main () {
    check_for_deps
    docker_check
    minikube_check
    kubectl_check
    popd > /dev/null 2>&1
}

main
