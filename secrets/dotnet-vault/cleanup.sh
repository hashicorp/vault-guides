#!/bin/bash

bash cleanup_vault_agent.sh

docker-compose down --remove-orphans
docker-compose rm