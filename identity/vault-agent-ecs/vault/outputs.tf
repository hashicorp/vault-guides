output "product_db_vault_path" {
  value       = local.products_creds_path
  description = "Database credentials path stored in HCP Vault"
}

output "product_api_role_arn" {
  value       = module.task_role.arn
  description = "Task IAM role ARN for product-api"
  sensitive   = true
}

output "product_api_role" {
  value       = vault_aws_auth_backend_role.ecs.role
  description = "Vault role name for product-api"
}