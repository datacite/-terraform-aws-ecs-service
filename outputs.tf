output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "aws_lb_listener_host_arn" {
  value = aws_lb_listener.host.arn
}

output "aws_lb_target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.log_gthisoup.name
}