provider "google" {
  credentials = "${file(var.account_file_path)}"
  project     = "${var.gcloud-project}"
  region      = "${var.gcloud-region}"
}

resource "google_compute_instance" "vault" {
  name         = "vault-test"
  machine_type = "n1-standard-1"
  zone         = "${var.gcloud-zone}"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  allow_stopping_for_update = true

  service_account {
    email = "${var.service_acct_email}"
    scopes = ["cloud-platform", "compute-rw", "userinfo-email", "storage-ro"]
  }

  metadata_startup_script = "${file(var.user_data)}"
}

// Create a KMS key ring
// resource "google_kms_key_ring" "key_ring" {
//   project  = "${var.gcloud-project}"
//   name     = "${var.key_ring}"
//   location = "${var.keyring_location}"
// }

// Create a crypto key for the key ring
// resource "google_kms_crypto_key" "crypto_key" {
//   name            = "${var.crypto-key}"
//   key_ring        = "${google_kms_key_ring.key_ring.self_link}"
//   rotation_period = "100000s"
// }
