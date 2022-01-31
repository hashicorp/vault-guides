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


variable "product_db_hostname" {
  type        = string
  description = "Amazon RDS database hostname"
}

variable "product_db_port" {
  type        = number
  description = "Amazon RDS database port"
  default     = 5432
}

variable "product_db_username" {
  type        = string
  description = "Amazon RDS database username"
}


variable "product_db_password" {
  type        = string
  description = "Amazon RDS database password"
  sensitive   = true
}

variable "product_api_efs_access_point_arn" {
  type        = string
  description = "ARN for EFS Access Point of product-api"
}


locals {
  tags = merge(var.tags, {
    Service = "hashicups"
    Purpose = "learn vault-agent-ecs"
  })
}