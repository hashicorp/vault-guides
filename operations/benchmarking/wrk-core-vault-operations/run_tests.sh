#!/usr/bin/env bash

# Run read test in background
# Make sure that the secrets already exist in Vault before running this test
# You can use write-secrets.lua (after some modification) to populate them
nohup wrk -t4 -c16 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s read-secrets.lua http://<vault_url>:8200 -- 1000 false > prod-test-read-1000-random-secrets-t4-c16-6hours.log &

# Run list test in background
# Make sure that the secrets already exist in Vault before running this test
# You can use write-secrets.lua (after some modification) to populate them
nohup wrk -t1 -c2 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s list-secrets.lua http://<vault_url>:8200 -- false > prod-test-list-100-secrets-t1-c2-6hours.log &

# Run authentication/revocation test in background
nohup wrk -t1 -c16 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s authenticate-and-revoke.lua http://<vault_url>:8200 > prod-test-authenticate-revoke-t1-c16-6hours.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 1 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test1.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 2 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test2.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 3 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test3.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 4 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test4.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 5 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test5.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 6 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test6.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 7 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test7.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 8 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test8.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 9 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test9.log &

# Run write/delete test in background
nohup wrk -t1 -c1 -d6h -H "X-Vault-Token: $VAULT_TOKEN" -s write-delete-secrets.lua http://<vault_url>:8200 -- 10 100 > prod-test-write-and-delete-100-secrets-t1-c1-6hours-test10.log &
