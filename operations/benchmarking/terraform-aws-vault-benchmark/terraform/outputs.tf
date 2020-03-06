output "bastion" {
  value = aws_instance.bastion.public_ip
}

output "key" {
  value = tls_private_key.main.private_key_pem
}

output "envoy_http" {
  value = "${aws_lb.envoy.dns_name}:80"
}

output "envoy_https" {
  value = "${aws_lb.envoy.dns_name}:443"
}

output "grafana" {
  value = "${aws_lb.telemetry.dns_name}:3000"
}

output "ca" {
  value = tls_self_signed_cert.root.cert_pem
}

