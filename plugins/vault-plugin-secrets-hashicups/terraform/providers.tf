terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.80"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "project" {
  project = var.project
  service = "container.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = false
  disable_on_destroy = false
}