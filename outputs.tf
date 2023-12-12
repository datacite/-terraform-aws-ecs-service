output "ecs_service_name" {
  value = try(aws_ecs_service.this[0].name, aws_ecs_service.ignore_task_definition[0].name, null)
}

output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.this[0].arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}