#!/bin/bash

docker-compose -f docker-compose-vault-agent-template.yml down
docker-compose -f docker-compose-vault-agent-template.yml rm

# the vault-agent-token file seems no longer in use for the exercise or the demo
# docker-compose -f docker-compose-vault-agent-token.yml down
# docker-compose -f docker-compose-vault-agent-token.yml rm
