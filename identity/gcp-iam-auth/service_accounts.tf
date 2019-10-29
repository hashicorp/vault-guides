resource "google_service_account" "vaultadmin" {
  project      = google_project.vault_gcp_iam_demo.project_id
  account_id   = "vaultadmin"
  display_name = "Vault Admin for IAM"
}

resource "google_service_account" "alice" {
  project      = google_project.vault_gcp_iam_demo.project_id
  account_id   = "alice-account"
  display_name = "Alice - Has access to things"
}

resource "google_service_account" "bob" {
  project      = google_project.vault_gcp_iam_demo.project_id
  account_id   = "bob-acount"
  display_name = "Bob - Does not have access to things"
}

resource "google_project_iam_member" "iam_admin_role" {
  role    = "roles/iam.serviceAccountKeyAdmin"
  project = google_project.vault_gcp_iam_demo.project_id
  member  = "serviceAccount:${google_service_account.vaultadmin.email}"
}

resource "google_project_iam_member" "sign_jwt_alice" {
  role    = "roles/iam.serviceAccountTokenCreator"
  project = google_project.vault_gcp_iam_demo.project_id
  member  = "serviceAccount:${google_service_account.alice.email}"
}

resource "google_project_iam_member" "sign_jwt_bob" {
  role    = "roles/iam.serviceAccountTokenCreator"
  project = google_project.vault_gcp_iam_demo.project_id
  member  = "serviceAccount:${google_service_account.bob.email}"
}

output "alice_account_email" {
  value = google_service_account.alice.email
}

output "bob_account_email" {
  value = google_service_account.bob.email
}
