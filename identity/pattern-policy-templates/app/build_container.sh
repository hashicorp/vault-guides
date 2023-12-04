#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


./build.sh
docker build -t kawsark/vault-example-init:0.0.9 .
rm vault-init
