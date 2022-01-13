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

variable "enable_ec2_launch_type" {
  type        = bool
  description = "Enable EC2 launch type"
  default     = false
}

variable "product_db_hostname" {
  type        = string
  description = "Amazon RDS database hostname"
  sensitive   = true
}

variable "product_api_role_arn" {
  type        = string
  description = "AWS Role ARN for Product API attached to Vault's AWS IAM Auth Method"
}

variable "product_api_role" {
  type        = string
  description = "Product API Vault role"
}

variable "product_db_vault_path" {
  type        = string
  description = "Product Database secrets path in Vault"
}

variable "vault_address" {
  type        = string
  description = "Vault address"
}

variable "vault_namespace" {
  type        = string
  description = "Vault namespace"
  default     = ""
}


variable "private_subnets" {
  type        = set(string)
  description = "List of private subnets for product-api"
}

variable "ecs_security_group" {
  type        = string
  description = "ECS security groups for product-api"
}

variable "database_security_group" {
  type        = string
  description = "Database security groups for product-api"
}

variable "target_group_arn" {
  type        = string
  description = "Target Group ARN for product-api"
}

variable "efs_file_system_id" {
  type        = string
  description = "ID of EFS file system for Vault Agents"
}

variable "product_api_efs_access_point_id" {
  type        = string
  description = "ID of EFS access point for product-api"
}

locals {
  tags = merge(var.tags, {
    Service = "hashicups"
    Purpose = "learn vault-agent-ecs"
  })
}