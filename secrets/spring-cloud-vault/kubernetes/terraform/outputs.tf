# Copyright IBM Corp. 2017, 2026

output "spring_ip" {
  value = "${kubernetes_service.spring-frontend.load_balancer_ingress.0.ip}"
}
