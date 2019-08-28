#--------------------------------------------
# REQUIRED: Google account credentials
#--------------------------------------------
variable "account_file_path" {
  description = "Your GCP account file location"
}

variable "project" {
  description = "Your GCP project name"
}

#--------------------------------------------
# General Variables
#--------------------------------------------
variable "gcloud-region" {
  description = "GCP region to spin up your GKE cluster in"
  default     = "us-west1"
}

variable "gcloud-zone" {
  description = "GCP zone to use"
  default     = "us-west1-a"
}

variable "linux_admin_username" {
  description = "User name for authentication to the Kubernetes linux agent virtual machines in the cluster."
  default     = "admin"
}

variable "linux_admin_password" {
  description = "The password for the Linux admin account."
  default     = "vault-agent-test-with-k8s"
}

variable "gcp_cluster_count" {
  description = "Count of cluster instances to start."
  default     = "1"
}

variable "cluster_name" {
  description = "Cluster name for the GCP Cluster."
  default     = "vault-test"
}

