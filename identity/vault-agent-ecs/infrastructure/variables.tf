variable "name" {
  type        = string
  description = "Name for infrastructure resources"
  default     = "learn"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to infrastructure resources"
  default     = {}
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "Region must be a valid one for HCP."
  }
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR Block"
  default     = "10.0.0.0/16"
}

variable "hcp_network_cidr_block" {
  type        = string
  description = "HCP CIDR Block for HashiCorp Virtual Network"
  default     = "172.25.16.0/20"
}

variable "client_cidr_block" {
  type        = string
  description = "CIDR Block to allow access to load balancer"
  default     = "0.0.0.0/0"
}

variable "database_username" {
  type        = string
  description = "Username for postgresql"
  default     = "postgres"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!_$"
}

locals {
  tags = merge(var.tags, {
    Service = "hashicups"
    Purpose = "learn vault-agent-ecs"
  })
}