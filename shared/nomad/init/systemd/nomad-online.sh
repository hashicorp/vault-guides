#!/usr/bin/env bash

NOMAD_ADDRESS=${1:-"127.0.0.1:4646"}

# waitForNomadToBeAvailable loops until the local Nomad agent returns a 200
# response at the /v1/status/leader endpoint.
#
# Parameters:
#     None
function waitForNomadToBeAvailable() {
  local nomad_addr=$1
  local nomad_leader_http_code

  nomad_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "${nomad_addr}/v1/status/leader") || nomad_leader_http_code=""

  while [ "x${nomad_leader_http_code}" != "x200" ] ; do
    sleep 5
    nomad_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "${nomad_addr}/v1/status/leader") || nomad_leader_http_code=""
  done
}

waitForNomadToBeAvailable "${NOMAD_ADDRESS}"
