#!/bin/bash

# This script will clean up locally provisioned resources
cd ../ && docker compose down
rm -rf terraform/terraform.tfstate*
rm -rf terraform/.terraform
rm -f docker-compose/vault-agent/*role_id
rm -f docker-compose/vault-agent/*secret_id
rm -f docker-compose/vault-agent/login.json
rm -f docker-compose/vault-agent/token
rm -f docker-compose/scripts/vault.txt
rm -f docker-compose/nginx/index.html
rm -f docker-compose/nginx/kv.html