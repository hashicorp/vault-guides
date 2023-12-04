#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


docker-compose -f docker-compose-vault-agent-template.yml down
docker-compose -f docker-compose-vault-agent-template.yml rm

docker-compose -f docker-compose-vault-agent-token.yml down
docker-compose -f docker-compose-vault-agent-token.yml rm