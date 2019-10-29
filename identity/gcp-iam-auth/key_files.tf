resource "google_service_account_key" "vaultadmin_credentials" {
  service_account_id = "${google_service_account.vaultadmin.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "vault_service_account_cred_file" {
  content  = "${base64decode(google_service_account_key.vaultadmin_credentials.private_key)}"
  filename = "${path.module}/vaultadmin-credentials.json"
}

resource "google_service_account_key" "bob_credentials" {
  service_account_id = "${google_service_account.bob.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "bob_cred_file" {
  content  = "${base64decode(google_service_account_key.bob_credentials.private_key)}"
  filename = "${path.module}/bob-credentials.json"
}

resource "google_service_account_key" "alice_credentials" {
  service_account_id = "${google_service_account.alice.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "alice_cred_file" {
  content  = "${base64decode(google_service_account_key.alice_credentials.private_key)}"
  filename = "${path.module}/alice-credentials.json"
}
