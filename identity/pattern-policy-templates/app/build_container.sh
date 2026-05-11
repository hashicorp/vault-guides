#!/bin/bash
# Copyright IBM Corp. 2017, 2026


./build.sh
docker build -t kawsark/vault-example-init:0.0.9 .
rm vault-init
