variable "family" {
  description = "Task definition [family](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#family). This is used by default as the Consul service name if `consul_service_name` is not provided."
  type        = string
}

variable "name" {
  description = "The name of the service. Defaults to the Task family name."
  type        = string
  default     = ""
}

variable "vault_address" {
  description = "The Vault address for the cluster."
  type        = string
}

variable "vault_namespace" {
  description = "The Vault namespace for the cluster."
  type        = string
  default     = null
}

variable "vault_agent_template" {
  description = "The base64-encoded Vault agent template to render secrets."
  type        = string
}

variable "vault_agent_template_file_name" {
  description = "File name of Vault agent template to render secrets. Default is `secrets`."
  type        = string
  default     = "secrets"
}

variable "vault_agent_exit_after_auth" {
  description = "Exit the Vault agent after it retrieves the credentials from Vault. Must be `true` or `false`. Default is `true`."
  type        = bool
  default     = true
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task."
  type        = list(string)
  default     = ["EC2", "FARGATE"]
}

variable "cpu" {
  description = "Number of cpu units used by the task."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task."
  type        = number
  default     = 512
}

variable "volumes" {
  description = "List of volumes to include in the aws_ecs_task_definition resource."
  type        = any
  default     = []
}

variable "task_role" {
  description = "ECS task role to include in the task definition. If not provided, a role is created."
  type = object({
    id  = string
    arn = string
  })
}

variable "execution_role" {
  description = "ECS execution role to include in the task definition. If not provided, a role is created."
  type = object({
    id  = string
    arn = string
  })
}

variable "efs_file_system_id" {
  description = "EFS file system ID for Vault agent in the ECS task definition"
  type        = string
}

variable "efs_access_point_id" {
  description = "EFS access point ID for Vault agent in the ECS task definition"
  type        = string
}

variable "vault_ecs_image" {
  description = "Vault agent ECS Docker image."
  type        = string
  default     = "ghcr.io/joatmon08/vault-agent-ecs:v1.11.0"
}

variable "log_configuration" {
  description = "Task definition [log configuration object](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html)."
  type        = any
  default     = null
}

variable "container_definitions" {
  description = "Application [container definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions)."
  # This is `any` on purpose. Using `list(any)` is too restrictive. It requires maps in the list to have the same key set, and same value types.
  type = any
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to add to ECS task resources."
  default     = {}
}

locals {
  tags = merge(var.tags, {
    Name        = var.name
    Module      = "vault-task-ecs"
    Description = "ECS task definition with Vault agent"
  })
}