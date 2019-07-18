data "http" "current_ip" {
  url = "http://ipv4.icanhazip.com/"
}

locals {
  bootstrap_script = templatefile(
    "${path.module}/templates/requester.sh.tpl",
    {
      vault_addr = "http://${google_compute_instance.vault_server.network_interface[0].access_config[0].nat_ip}:8200"
    },
  )
}

resource "google_compute_network" "vault_gcp_demo_network" {
  project    = google_project.vault_gcp_demo.project_id
  name       = "vault-gcp-demo"
  depends_on = [google_project_services.vault_gcp_demo_services]
}

resource "google_compute_firewall" "allow_vault_access" {
  project    = google_project.vault_gcp_demo.project_id
  name       = "allow-vault-access"
  network    = google_compute_network.vault_gcp_demo_network.self_link
  depends_on = [
    google_project_services.vault_gcp_demo_services,
    google_compute_instance.vault_happy,
    google_compute_instance.vault_sad,
  ]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "8200"]
  }
  source_ranges = [
    "${chomp(data.http.current_ip.body)}/32",
    "${google_compute_instance.vault_happy.network_interface[0].access_config[0].nat_ip}/32",
    "${google_compute_instance.vault_sad.network_interface[0].access_config[0].nat_ip}/32",
  ]
  target_tags = ["vault-server", "vault-requester"]
}

resource "google_compute_instance" "vault_server" {
  name         = "vault-server"
  machine_type = "n1-standard-1"
  zone         = "europe-west2-a"
  project      = google_project.vault_gcp_demo.project_id
  tags         = ["vault-server"]
  depends_on   = [google_project_services.vault_gcp_demo_services]
  network_interface {
    network = google_compute_network.vault_gcp_demo_network.self_link
    access_config { # Public-facing IP
    }
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  metadata_startup_script = file("./scripts/install_vault.sh")
  service_account {
    email  = google_service_account.vault_auth_checker.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "vault_happy" {
  name         = "vault-requester-happy"
  machine_type = "f1-micro"
  zone         = "europe-west2-a"
  project      = google_project.vault_gcp_demo.project_id
  tags         = ["vault-requester"]
  depends_on   = [google_project_services.vault_gcp_demo_services]
  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  metadata_startup_script = local.bootstrap_script
  service_account {
    email  = "${google_service_account.vault_auth_checker.email}"
    scopes = ["cloud-platform"]
  }
}
resource "google_compute_instance" "vault_sad" {
  name         = "vault-requester-sad"
  machine_type = "f1-micro"
  zone         = "europe-west1-b"
  project      = google_project.vault_gcp_demo.project_id
  tags         = ["vault-requester"]
  depends_on   = [google_project_services.vault_gcp_demo_services]
  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  metadata_startup_script = local.bootstrap_script
  service_account {
    email  = "${google_service_account.vault_auth_checker.email}"
    scopes = ["cloud-platform"]
  }
}
output "vault_server_instance_id" {
  value = google_compute_instance.vault_server.self_link
}
output "vault_happy_instance_id" {
  value = google_compute_instance.vault_happy.self_link
}
output "vault_sad_instance_id" {
  value = google_compute_instance.vault_sad.self_link
}
output "vault_addr_export" {
  value = "Run the following for the Vault configuration: export VAULT_ADDR=http://${google_compute_instance.vault_server.network_interface[0].access_config[0].nat_ip}:8200"
}
