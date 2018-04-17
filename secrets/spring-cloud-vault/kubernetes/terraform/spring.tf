resource "kubernetes_replication_controller" "spring-frontend" {
  metadata {
    name = "spring-frontend"
    labels {
      App = "spring-frontend"
    }
  }

  spec {
    replicas = 0
    selector {
      App = "spring-frontend"
    }
    template {
    service_account_name = "${kubernetes_service_account.spring.metadata.0.name}"
    container {
        image = "${var.spring_docker_container}"
        image_pull_policy = "Always"
        name = "spring"
        volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name = "${kubernetes_service_account.spring.default_secret_name}"
        }
        volume_mount {
            mount_path = "/bootstrap.yaml"
            sub_path = "bootstrap.yaml"
            name = "${kubernetes_config_map.spring.metadata.0.name}"
        }
        port {
            container_port = 8080
        }
    }
    volume {
        name = "${kubernetes_service_account.spring.default_secret_name}"
        secret {
            secret_name = "${kubernetes_service_account.spring.default_secret_name}"
        }
    }
    volume {
        name = "${kubernetes_config_map.spring.metadata.0.name}"
        config_map {
            name = "spring"
            items {
                key = "config"
                path =  "bootstrap.yaml"
            }
        }
    }
    }
  }
}

resource "kubernetes_service" "spring-frontend" {
    metadata {
        name = "spring-frontend"
    }
    spec {
        selector {
            App = "${kubernetes_replication_controller.spring-frontend.metadata.0.labels.App}"
        }
        port {
            port = 8080
            target_port = 8080
        }
        type = "LoadBalancer"
    }
}

resource "kubernetes_config_map" "spring" {
  metadata {
    name = "spring"
  }
  data {
    config = <<EOF
---
spring.application.name: spring-vault-demo
spring.cloud.vault:
    authentication: KUBERNETES
    kubernetes:
        role: ${var.vault_role}
        service-account-token-file: /var/run/secrets/kubernetes.io/serviceaccount/token
    host: ${var.vault_host}
    port: ${var.vault_port}
    scheme: http
    fail-fast: true
    config.lifecycle.enabled: true
    database:
        enabled: true
        role: ${var.postgres_role}
        backend: database
spring.datasource:
    url: jdbc:postgresql://${var.postgres_host}:${var.postgres_port}/${var.postgres_instance}
EOF
  }
}
