# Copyright IBM Corp. 2017, 2026

output "arn" {
  value       = aws_iam_role.task.arn
  description = "ARN of task IAM role"
}