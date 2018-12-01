resource "google_service_account_key" "vault_auth_checker_credentials" {
  service_account_id = "${google_service_account.vault_auth_checker.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "vault_service_account_cred_file" {
  content  = "${base64decode(google_service_account_key.vault_auth_checker_credentials.private_key)}"
  filename = "${path.module}/${google_service_account.vault_auth_checker.account_id}-credentials.json"
}
