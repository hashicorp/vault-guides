#!/bin/bash

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='some-root-token'

cd ProjectApi

dotnet restore

VAULT_SECRET_ID=$(cat vault-agent/secret-id) dotnet run