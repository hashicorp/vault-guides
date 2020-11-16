#!/bin/bash

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='some-root-token'

docker-compose -f docker-compose-agent.yml up -d