#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


cd application
terraform destroy -auto-approve

vault lease revoke -f -prefix learn/database

cd ../vault
terraform destroy -auto-approve

cd ../infrastructure
terraform destroy -auto-approve