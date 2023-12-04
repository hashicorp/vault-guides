#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


bash cleanup_vault_agent.sh

docker-compose down --remove-orphans
docker-compose rm