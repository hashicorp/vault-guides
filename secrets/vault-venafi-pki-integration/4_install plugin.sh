#!/bin/bash
export VAULT_ADDR=http://127.0.0.1:8200
# Get the SHA-256 checksum of vault-pki-monitor-venafi plugin binary from checksum file:
SHA256=$(cut -d' ' -f1 vault-pki-monitor-venafi_0.4.0+181_linux_strict.SHA256SUM)
echo $SHA256
# Add the vault-pki-monitor-venafi plugin to the Vault system catalog:
vault write sys/plugins/catalog/secret/vault-pki-monitor-venafi_strict sha_256="${SHA256}" command="vault-pki-monitor-venafi_strict"