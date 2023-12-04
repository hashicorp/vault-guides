# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.env}-"
}

