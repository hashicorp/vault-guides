output "file_system_id" {
  value       = aws_efs_file_system.mount.id
  description = "ID of EFS file system for ECS tasks with Vault agents"
}

output "file_system_arn" {
  value       = aws_efs_file_system.mount.arn
  description = "ARN of EFS file system ID for ECS tasks with Vault agents"
}