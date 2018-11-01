variable vault_url {
  default = "https://releases.hashicorp.com/vault/1.0.0-beta1/vault_1.0.0-beta1_linux_amd64.zip"
}

variable gcloud-project {
  description = "Google project name"
}

variable gcloud-region {
  default = "us-east1"
}

variable gcloud-zone {
  default = "us-east1-b"
}

variable account_file_path {
  description = "Path to GCP account file"
}

variable user_data {
  default = "init.sh"
}

variable key_ring {
  description = "Cloud KMS key ring name to create"
  default = "test"
}

variable service_acct_email {
  description = "An email of the service account for instance"
}

variable crypto_key {
  default = "vault-test"
  description = "Crypto key name to create under the key ring"
}

variable keyring_location {
  default = "global"
}
