#!/bin/bash
# Copyright IBM Corp. 2017, 2026


cd application
terraform destroy -auto-approve

vault lease revoke -f -prefix learn/database

cd ../vault
terraform destroy -auto-approve

cd ../infrastructure
terraform destroy -auto-approve