#!/bin/bash

[ ! -n "$DEBUG" ] || set -x

set -ue

# the internet says this is better than 'set -e'
function onerr {
    echo 'Cleaning up after error...'
    exit -1
}
trap onerr ERR


function check_deps () {
    for i in inspec ; do
        if ! command -v $i > /dev/null 2>&1 ; then
            echo "Failed to find \'$i\' in PATH\!"
            exit -1
        else
            echo "Found $i in PATH..."
        fi
    done
}


function run_tests () {
    RUBYOPT=-W0 inspec exec validate.d/inspec
}


function main () {
    check_deps
    run_tests
}

main
