# -terraform-aws-ecs-service
Module for creating a aws ecs service

- Runs an ECS Service with attached default load balancer or not
- Creates a default target group for the service if required (var.setup_alb)
- Creates a default listener for the service if required (var.setup_alb)
- Sets up cloudwatch logs
- Supports either task definitions to be managed via terraform state or externally (var.managed_externally)
- Can specify container definitions or by default will use a basic nginx for initial setup. (var.container_definitions)
