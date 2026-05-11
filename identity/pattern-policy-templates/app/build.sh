#!/bin/bash
# Copyright IBM Corp. 2017, 2026

GOOS=linux go build \
  -a --ldflags '-extldflags "-static"' \
  -tags netgo \
  -installsuffix netgo \
  -o vault-init .
