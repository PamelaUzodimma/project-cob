# main.tf — Compute (ECS) capability
#
# WHAT THIS GIVES A CONSUMING TEAM:
#   - An ECS cluster
#   - A Fargate task definition with correct execution-role wiring
#   - A running service maintaining desired_count healthy tasks
#   - CloudWatch logging pre-wired (no "where did my logs go")
#   - A security group scoped to only the container's port
#   - Consistent naming/tagging
#
# A team calling this module does NOT need to know: how ECS execution
# roles differ from task roles, that Fargate requires awsvpc network
# mode, how to wire a log driver, or how task definitions reference
# log groups. That knowledge is encoded here once.

locals {
  name_prefix = "${var.project}-${var.environment}-${var.service_name}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner_team
    ManagedBy   = "terraform"
    Platform    = "cob"
    Service     = var.service_name
  }

  # Default ingress to "nobody" if the caller didn't specify -- forces
  # a deliberate choice rather than silently opening to 0.0.0.0/0.
  ingress_cidrs = length(var.ingress_cidr_blocks) > 0 ? var.ingress_cidr_blocks : []
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

# Execution role: lets ECS pull the image and write logs. Generic
# boilerplate every task needs -- created here, not by the caller.
data "aws_iam_policy_document" "execution_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name_prefix}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_trust.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "service" {
  name        = "${local.name_prefix}-sg"
  description = "Allows inbound to container port ${var.container_port} only"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.ingress_cidrs
    content {
      description = "Container port"
      from_port   = var.container_port
      to_port     = var.container_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

data "aws_region" "current" {}

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  tags = local.common_tags
}
