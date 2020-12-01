#!/bin/bash

docker-compose -f docker-compose-vault-agent-template.yml down
docker-compose -f docker-compose-vault-agent-template.yml rm

docker-compose -f docker-compose-vault-agent-token.yml down
docker-compose -f docker-compose-vault-agent-token.yml rm