#!/usr/bin/env bash
set -x

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

vault login password

#Generic policies
echo '
path "sys/mounts" {
  capabilities = ["list","read"]
}
path "secret/*" {
  capabilities = ["list", "read"]
}
path "secret/me" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "supersecret/*" {
  capabilities = ["list", "read"]
}
path "ssh-client-signer/*" {
  capabilities = ["read","list","create","update"]
}
path "aws/*" {
  capabilities = ["read","list","create","update"]
}
path "ssh/*" {
  capabilities = ["read","list","create","update"]
}'  | vault policy write vault -

vault auth enable userpass
vault write auth/userpass/users/vault password=vault policies=vault
