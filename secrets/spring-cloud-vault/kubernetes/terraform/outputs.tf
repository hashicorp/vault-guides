output "spring_ip" {
  value = "${kubernetes_service.spring-frontend.load_balancer_ingress.0.ip}"
}
