# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

service {
  name = "webapp",
  port = 80,
  check {
    http = "http://demo-webapp",
    interval = "5s"
  }
}
