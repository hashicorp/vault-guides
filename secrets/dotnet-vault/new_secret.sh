#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='some-root-token'

vault write -f -field=secret_id auth/approle/role/projects-api-role/secret-id > ProjectApi/vault-agent/secret-id