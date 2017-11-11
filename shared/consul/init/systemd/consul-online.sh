#!/usr/bin/env bash

set -e
set -o pipefail

CONSUL_ADDRESS=${1:-"127.0.0.1:8500"}

# waitForConsulToBeAvailable loops until the local Consul agent returns a 200
# response at the /v1/operator/raft/configuration endpoint.
#
# Parameters:
#     None
function waitForConsulToBeAvailable() {
  local consul_addr=$1
  local consul_leader_http_code

  consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "${consul_addr}/v1/operator/raft/configuration") || consul_leader_http_code=""

  while [ "x${consul_leader_http_code}" != "x200" ] ; do
    echo "Waiting for Consul to get a leader..."
    sleep 5
    consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "${consul_addr}/v1/operator/raft/configuration") || consul_leader_http_code=""
  done
}

waitForConsulToBeAvailable "${CONSUL_ADDRESS}"
