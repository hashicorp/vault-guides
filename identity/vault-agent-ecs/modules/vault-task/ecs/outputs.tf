# Copyright IBM Corp. 2017, 2026

output "task_definition_arn" {
  value = aws_ecs_task_definition.task.arn
}