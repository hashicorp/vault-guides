#!/bin/bash
# Copyright IBM Corp. 2017, 2026


bash cleanup_vault_agent.sh

docker-compose down --remove-orphans
docker-compose rm