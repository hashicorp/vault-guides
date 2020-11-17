#!/bin/bash

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='some-root-token'

docker-compose -f docker-compose-vault-agent-token.yml up -d

sleep 10

cd ProjectApi && consul-template -config ./vault-agent/config-consul-template.hcl