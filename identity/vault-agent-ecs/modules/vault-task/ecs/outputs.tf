# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "task_definition_arn" {
  value = aws_ecs_task_definition.task.arn
}