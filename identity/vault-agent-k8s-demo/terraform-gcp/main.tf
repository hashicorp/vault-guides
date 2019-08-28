provider "google" {
  credentials = file(var.account_file_path)
  project     = var.project
  region      = var.gcloud-region
}

resource "google_container_cluster" "gcp_kubernetes" {
  name               = var.cluster_name
  location           = var.gcloud-zone
  initial_node_count = var.gcp_cluster_count

  # Temporal workaround for Google provider issue $4010
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  master_auth {
    username = var.linux_admin_username
    password = "${var.linux_admin_password}}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      this-is-for = "dev-cluster"
    }

    tags = ["dev", "work"]
  }
}

#--------------------------------------------
# Outputs
#--------------------------------------------
output "gcp_cluster_endpoint" {
  value = google_container_cluster.gcp_kubernetes.endpoint
}

output "gcp_cluster_name" {
  value = google_container_cluster.gcp_kubernetes.name
}

output "gcp_ssh_command" {
  value = "ssh ${var.linux_admin_username}@${google_container_cluster.gcp_kubernetes.endpoint}"
}

output "gcp_zone" {
  value = google_container_cluster.gcp_kubernetes.location
}

output "gcp_project" {
  value = var.project
}
