variable "billing_account" {}

variable "org_id" {}

provider "google" {
  version = "1.16.2"
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = "vault-gcp-demo-"
}

resource "google_project" "vault_gcp_demo" {
  name            = "vault-gcp-demo"
  project_id      = "${random_id.id.hex}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
}

resource "google_project_services" "vault_gcp_demo_services" {
  project = "${google_project.vault_gcp_demo.project_id}"

  services = [
    "oslogin.googleapis.com",
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
  ]
}

output "project_id" {
  value = "${google_project.vault_gcp_demo.project_id}"
}

resource "google_service_account" "vault_auth_checker" {
  project      = "${google_project.vault_gcp_demo.project_id}"
  account_id   = "vault-auth-checker"
  display_name = "Vault Auth Checker"
}

resource "google_project_iam_policy" "vault_policy" {
  project     = "${google_project.vault_gcp_demo.project_id}"
  policy_data = "${data.google_iam_policy.vault_policy.policy_data}"
}

data "google_iam_policy" "vault_policy" {
  binding {
    role = "roles/compute.viewer"

    members = [
      "serviceAccount:${google_service_account.vault_auth_checker.email}",
    ]
  }

  binding {
    role = "roles/iam.securityReviewer"

    members = [
      "serviceAccount:${google_service_account.vault_auth_checker.email}",
    ]
  }
}
