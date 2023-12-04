#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


echo "Printing Docker service IP addresses"
for s in `docker-compose ps -q`; do echo ip of `docker inspect -f "{{.Name}}" $s` is `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $s`; done
