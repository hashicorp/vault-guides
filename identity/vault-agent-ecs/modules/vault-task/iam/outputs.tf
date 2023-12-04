# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "arn" {
  value       = aws_iam_role.task.arn
  description = "ARN of task IAM role"
}