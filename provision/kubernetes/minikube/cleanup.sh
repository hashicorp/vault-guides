#!/bin/bash

[ ! -n "$DEBUG" ] || set -x

set -ue

# the internet says this is better than 'set -e'
function onerr {
    echo 'Cleaning up after error...'
    exit -1
}
trap onerr ERR

set -x

for i in vault consul; do
    kubectl delete -f $i.yml || true
done

for i in $(kubectl get pvc --no-headers | cut -f1 -d' '); do
    kubectl delete pvc $i;
done

for i in $(kubectl get pv --no-headers | cut -f1 -d' '); do
    kubectl delete pv $i;
done
