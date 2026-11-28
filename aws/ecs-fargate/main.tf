data "aws_region" "current" {}

data "aws_vpc" "this" {
  count = local.create_security_group && var.egress_cidr_blocks == null ? 1 : 0
  id    = var.vpc_id
}

# Las capas de ECR se descargan de S3 por el endpoint de puerta de enlace.
data "aws_ec2_managed_prefix_list" "s3" {
  count = local.create_security_group ? 1 : 0
  name  = "com.amazonaws.${data.aws_region.current.region}.s3"
}

locals {
  create_security_group = var.security_group_ids == null
  security_group_ids    = local.create_security_group ? aws_security_group.this[*].id : var.security_group_ids
  egress_cidr_blocks    = var.egress_cidr_blocks != null ? var.egress_cidr_blocks : data.aws_vpc.this[*].cidr_block
  assume_ecs_tasks = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_ecs_cluster" "this" {
  name = var.name
  tags = var.tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-execution"
  assume_role_policy = local.assume_ecs_tasks
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0
  name  = "read-task-secrets"
  role  = aws_iam_role.execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "ssm:GetParameters"]
      Resource = distinct(values(var.secrets))
    }]
  })
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = local.assume_ecs_tasks
  tags               = var.tags
}

resource "aws_iam_role_policy" "task" {
  count  = var.task_role_policy_json == null ? 0 : 1
  name   = "application"
  role   = aws_iam_role.task.id
  policy = var.task_role_policy_json
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  tags                     = var.tags

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name                   = var.name
    image                  = var.image
    essential              = true
    readonlyRootFilesystem = true
    portMappings           = [{ containerPort = var.container_port, protocol = "tcp" }]
    environment            = [for key in sort(keys(var.environment)) : { name = key, value = var.environment[key] }]
    secrets                = [for key in sort(keys(var.secrets)) : { name = key, valueFrom = var.secrets[key] }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = var.name
      }
    }
  }])
}

resource "aws_security_group" "this" {
  count       = local.create_security_group ? 1 : 0
  name        = "${var.name}-tasks"
  description = "Tareas del servicio ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-tasks" })
}

resource "aws_vpc_security_group_ingress_rule" "source" {
  count                        = local.create_security_group && var.source_security_group_id != null ? 1 : 0
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = var.source_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  description                  = "Llamadas al contenedor"
}

# HTTPS hacia los endpoints de la VPC y S3. Otros destinos se agregan en el consumidor.
resource "aws_vpc_security_group_egress_rule" "https" {
  for_each          = local.create_security_group ? toset(local.egress_cidr_blocks) : toset([])
  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.value
  description       = "HTTPS saliente"
}

resource "aws_vpc_security_group_egress_rule" "s3" {
  count             = local.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3[0].id
  description       = "Capas de imagen en S3"
}

resource "aws_ecs_service" "this" {
  name                   = var.name
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  platform_version       = "LATEST"
  enable_execute_command = false
  propagate_tags         = "SERVICE"
  tags                   = var.tags

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = local.security_group_ids
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]
    content {
      target_group_arn = load_balancer.value
      container_name   = var.name
      container_port   = var.container_port
    }
  }
}
