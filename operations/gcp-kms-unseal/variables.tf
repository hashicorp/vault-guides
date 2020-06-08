variable "vault_url" {
  default = "https://releases.hashicorp.com/vault/1.4.2/vault_1.4.2_linux_amd64.zip"
}

variable "gcloud-project" {
  description = "Google project name"
}

variable "gcloud-region" {
  default = "us-east1"
}

variable "gcloud-zone" {
  default = "us-east1-b"
}

variable "account_file_path" {
  description = "Path to GCP account file"
}

variable "key_ring" {
  description = "Cloud KMS key ring name to create"
  default     = "test"
}

variable "crypto_key" {
  default     = "vault-test"
  description = "Crypto key name to create under the key ring"
}

variable "keyring_location" {
  default = "global"
}
