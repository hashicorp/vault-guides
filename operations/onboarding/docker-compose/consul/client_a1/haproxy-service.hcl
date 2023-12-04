# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

service {
  name = "haproxy",
  port = 80,
  check {
    http = "http://demo-haproxy",
    interval = "5s"
  }
}
