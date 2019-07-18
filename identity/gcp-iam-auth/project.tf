variable "billing_account" {
}

variable "org_id" {
}

resource "random_id" "id" {
  byte_length = 1
  prefix      = "vaultguides-gcpiam-"
}

resource "google_project" "vault_gcp_iam_demo" {
  name            = "vault-gcp-iam-demo"
  project_id      = random_id.id.hex
  billing_account = var.billing_account
  org_id          = var.org_id
}

resource "google_project_services" "vault_gcp_iam_demo_services" {
  project = google_project.vault_gcp_iam_demo.project_id

  services = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
  ]
}

output "project_id" {
  value = google_project.vault_gcp_iam_demo.project_id
}
