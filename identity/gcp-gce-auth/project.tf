locals {
  server_read_roles = [
    "roles/compute.viewer",
    "roles/iam.securityReviewer",
  ]
}

variable "billing_account" {
}

variable "org_id" {
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = "vault-guides-gcp-demo-"
}

resource "google_project" "vault_gcp_demo" {
  name            = "vault-gcp-demo"
  project_id      = random_id.id.hex
  billing_account = var.billing_account
  org_id          = var.org_id
}

resource "google_project_services" "vault_gcp_demo_services" {
  project = google_project.vault_gcp_demo.project_id

  services = [
    "oslogin.googleapis.com",
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_service_account" "vault_auth_checker" {
  project      = google_project.vault_gcp_demo.project_id
  account_id   = "vault-auth-checker"
  display_name = "Vault Auth Checker"
}

resource "google_project_iam_member" "server_roles" {
  count   = length(local.server_read_roles)
  role    = local.server_read_roles[count.index]
  project = google_project.vault_gcp_demo.project_id
  member  = "serviceAccount:${google_service_account.vault_auth_checker.email}"
}

output "project_id" {
  value = google_project.vault_gcp_demo.project_id
}
