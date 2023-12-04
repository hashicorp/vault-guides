#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

GOOS=linux go build \
  -a --ldflags '-extldflags "-static"' \
  -tags netgo \
  -installsuffix netgo \
  -o vault-init .
