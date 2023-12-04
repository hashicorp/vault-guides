# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "spring_ip" {
  value = "${kubernetes_service.spring-frontend.load_balancer_ingress.0.ip}"
}
