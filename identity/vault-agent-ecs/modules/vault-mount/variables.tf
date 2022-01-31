variable "name" {
  type        = string
  description = "Name for task that runs with Vault agent"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnets for EFS mount"
}

variable "ecs_security_group" {
  type        = string
  description = "Security group for ECS cluster"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to add to EFS resources."
  default     = {}
}

locals {
  tags = merge(var.tags, {
    Name        = var.name
    Module      = "vault-mount"
    Description = "EFS volume for Vault agents in ECS cluster"
  })
}