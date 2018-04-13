provider "kubernetes" {
    host = "${var.k8s_endpoint}"
    client_certificate = "${base64decode(var.k8s_master_auth_client_certificate)}"
    client_key = "${base64decode(var.k8s_master_auth_client_key)}"
    cluster_ca_certificate = "${base64decode(var.k8s_master_auth_cluster_ca_certificate)}"
}

resource "kubernetes_service_account" "spring" {
    metadata {
        name = "spring"
    }
}

resource "kubernetes_service_account" "vault" {
    metadata {
        name = "vault"
    }
}
