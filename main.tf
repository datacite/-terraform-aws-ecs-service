data "aws_ecs_cluster" "this" {
  cluster_name = var.env
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_lb" "this" {
  name = var.lb_name
}

data "aws_lb_listener" "this" {
  load_balancer_arn = data.aws_lb.this.arn
  port = 443
}

data "aws_region" "current" {}

locals {
  awslogs_group = "/ecs/${var.app_name}-${var.env}"

  # This is a default configuration that uses nginx
  # Exposes http port and sets up logging
  default_container_definitions = jsonencode(
    [{
      "name": "nginx",
      "image": "nginx:latest",
      "cpu": var.fargate_cpu,
      "memory": var.fargate_memory,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": local.awslogs_group,
          "awslogs-region": data.aws_region.current.name,
          "awslogs-stream-prefix": "ecs"
        }
      }
    }]
  )

  # Whichever has the higher revision gets used as task definition
  # This is used to handle external management of task definitions
  # i.e. The tasks are not created and updated by terraform state
  task_definition = "${aws_ecs_task_definition.this.family}:${max(
    aws_ecs_task_definition.this.revision,
    data.aws_ecs_task_definition.this.revision,
  )}"

}

resource "aws_ecs_task_definition" "this" {
  family = "${var.app_name}-${var.env}"
  network_mode = "awsvpc"

  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

  requires_compatibilities = compact([var.use_fargate ? "FARGATE" : ""])

  # For fargate if we are using fargate (default) then we get from variables details
  # Otherwise don't specify task limits
  cpu                      = var.use_fargate ? var.fargate_cpu : ""
  memory                   = var.use_fargate ? var.fargate_memory : ""

  # The definition for the container either comes from a var or we use a default which is just nginx
  container_definitions =  var.container_definitions == "" ? local.default_container_definitions : var.container_definitions

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family

  depends_on = [
    aws_ecs_task_definition.this
  ]
}

resource "aws_ecs_service" "this" {
  count = !var.managed_externally ? 1 : 0

  name            = "${var.app_name}-${var.env}"
  launch_type     = var.launch_type
  cluster         = data.aws_ecs_cluster.this.id
  desired_count   = var.desired_container_count

  # See local definition above but here this is either going to be latest revision from external data
  # or the latest revision from the task definition we are creating
  task_definition = local.task_definition

  network_configuration {
    security_groups = var.security_group_ids
    subnets         = var.subnet_ids
  }

  # Associate and setup the load balancer if required
  dynamic "load_balancer" {
    for_each = var.setup_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].id
      container_name   = "${var.app_name}-${var.env}"
      container_port   = var.container_port
    }
  }

  service_registries {
    registry_arn = aws_service_discovery_service.this.arn
  }

  # tags = merge(
  #     var.tags,
  #     {
  #       Name = "${var.app_name}-${var.env}"
  #     },
  # )

}

# This is a duplicate of the main service resource but with the task definition ignored
# This is used to handle external management of task definitions
# This is because lifecycle values must be literals.
resource "aws_ecs_service" "ignore_task_definition" {
  count = var.managed_externally ? 1 : 0

  name            = "${var.app_name}-${var.env}"
  launch_type     = var.launch_type
  cluster         = data.aws_ecs_cluster.this.id
  desired_count   = var.desired_container_count

  # See local definition above but here this is either going to be latest revision from external data
  # or the latest revision from the task definition we are creating
  task_definition = local.task_definition

  network_configuration {
    security_groups = var.security_group_ids
    subnets         = var.subnet_ids
  }

  # Associate and setup the load balancer if required
  dynamic "load_balancer" {
    for_each = var.setup_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].id
      container_name   = var.app_name
      container_port   = var.container_port
    }
  }

  service_registries {
    registry_arn = aws_service_discovery_service.this.arn
  }

  tags = merge(
      var.tags,
      {
        Name = "${var.app_name}-${var.env}"
      },
  )

  lifecycle {
    ignore_changes = [
      task_definition,
     ]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.app_name}-${var.env}"
}

resource "aws_service_discovery_service" "this" {
  name = "${var.app_name}.${var.env}"

  health_check_custom_config {
    failure_threshold = 3
  }

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl = 300
      type = "A"
    }
  }
}

resource "aws_lb_target_group" "this" {
  count = var.setup_alb ? 1 : 0

  name     = "${var.app_name}-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  slow_start = 240

  health_check {
    path = var.health_check_path
  }
}


resource "aws_lb_listener_rule" "host" {
  count = var.setup_alb ? 1 : 0

  listener_arn = data.aws_lb_listener.this.arn
  priority     = var.lb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].id
  }

  condition {
    host_header {
      values = [var.dns_record_name]
    }
  }
}