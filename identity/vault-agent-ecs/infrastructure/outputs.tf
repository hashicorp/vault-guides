output "hcp_vault_public_endpoint" {
  value       = module.hcp.hcp_vault_public_endpoint
  description = "Public endpoint of HCP Vault"
  sensitive   = true
}

output "hcp_vault_private_endpoint" {
  value       = module.hcp.hcp_vault_private_endpoint
  description = "Private endpoint of HCP Vault"
  sensitive   = true
}

output "hcp_vault_admin_token" {
  value       = hcp_vault_cluster_admin_token.cluster.token
  description = "Token of HCP Vault"
  sensitive   = true
}

output "product_database_hostname" {
  value       = aws_lb.nlb.dns_name
  description = "Load balancer hostname for product-db hosted on ECS cluster"
}

output "product_database_username" {
  value       = var.database_username
  description = "Database username for product-db hosted on ECS cluster"
}

output "product_database_password" {
  value       = random_password.password.result
  description = "Database password for product-db hosted on ECS cluster"
  sensitive   = true
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "Subnet IDs for private subnets"
}

output "ecs_security_group" {
  value       = aws_security_group.ecs.id
  description = "Security group ID for ECS cluster"
}

output "database_security_group" {
  value       = aws_security_group.database.id
  description = "Security group ID for product-db"
}

output "target_group_arn" {
  value       = aws_lb_target_group.product_api.arn
  description = "Target group ARN for product-api"
  sensitive   = true
}

output "efs_file_system_id" {
  value       = module.efs.file_system_id
  description = "EFS file system ID for Vault agents on ECS"
}

output "product_api_efs_access_point_arn" {
  value       = aws_efs_access_point.product_api.arn
  description = "EFS access point ARN for Vault agents on ECS"
  sensitive   = true
}

output "product_api_efs_access_point_id" {
  value       = aws_efs_access_point.product_api.id
  description = "EFS access point ID for Vault agents on ECS"
}

output "product_api_endpoint" {
  value       = aws_lb.alb.dns_name
  description = "Load balancer hostname for product-api hosted on ECS cluster"
}