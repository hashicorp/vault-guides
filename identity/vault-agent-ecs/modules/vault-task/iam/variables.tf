variable "name" {
  type        = string
  description = "Name for task that runs with Vault agent"
}

variable "ecs_task_efs_access_point_arn" {
  type        = string
  description = "EFS access point for task"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to add to IAM task resources."
  default     = {}
}

locals {
  tags = merge(var.tags, {
    Name        = var.name
    Module      = "vault-task-iam"
    Description = "Task IAM Role for Vault agents in ECS cluster"
  })
}