#!/usr/bin/env bash

set -e
set -o pipefail

function waitForVaultToken() {
  local path=$1

  while [ ! -s "${path}" ] ; do
    echo "Waiting for file..."
    sleep 1
  done

  echo "File found."
}

waitForVaultToken "/secrets/nomad-server-token"
