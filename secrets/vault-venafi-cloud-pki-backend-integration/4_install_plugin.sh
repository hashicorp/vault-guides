#!/bin/bash
export VAULT_ADDR=http://127.0.0.1:8200
# Get the SHA-256 checksum of vault-pki-backend-venafi plugin binary from checksum file:
SHA256=$(shasum -a 256 /etc/vault/plugins/venafi-pki-backend| cut -d' ' -f1)
echo $SHA256
# Add the vault-pki-backend-venafi plugin to the Vault system catalog:
vault write sys/plugins/catalog/secret/venafi-pki-backend sha_256="${SHA256}" command="venafi-pki-backend"
