mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.0.0.0/16" }
  }
  mock_data "aws_ec2_managed_prefix_list" {
    defaults = { id = "pl-63a5400a" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/poc-api" }
  }
  mock_resource "aws_ecs_task_definition" {
    defaults = { arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/poc-api:1" }
  }
}

variables {
  name       = "poc-api"
  image      = "123456789012.dkr.ecr.us-east-1.amazonaws.com/poc/api:1.0.0"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
}

run "service_defaults" {
  command = apply

  assert {
    condition     = aws_ecs_service.this.network_configuration[0].assign_public_ip == false && aws_ecs_service.this.enable_execute_command == false
    error_message = "Las tareas no tienen IP pública ni ejecución remota de comandos."
  }

  assert {
    condition     = aws_ecs_service.this.deployment_circuit_breaker[0].rollback && aws_ecs_service.this.desired_count == 2
    error_message = "Dos tareas por defecto y reversión automática de despliegues fallidos."
  }

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this.container_definitions)[0].readonlyRootFilesystem && jsondecode(aws_ecs_task_definition.this.container_definitions)[0].logConfiguration.options["awslogs-group"] == "/ecs/poc-api"
    error_message = "El contenedor usa sistema de archivos de solo lectura y envía sus logs al grupo del servicio."
  }

  assert {
    condition     = one([for setting in aws_ecs_cluster.this.setting : setting.value if setting.name == "containerInsights"]) == "enabled"
    error_message = "Container Insights queda habilitado."
  }

  assert {
    condition     = length(aws_iam_role_policy.task) == 0 && length(aws_iam_role_policy.execution_secrets) == 0 && length(aws_vpc_security_group_ingress_rule.source) == 0
    error_message = "Sin entradas opcionales no se conceden permisos ni entrada de red."
  }

  assert {
    condition     = keys(aws_vpc_security_group_egress_rule.https) == ["10.0.0.0/16"] && aws_vpc_security_group_egress_rule.s3[0].prefix_list_id == "pl-63a5400a" && length(aws_ecs_service.this.load_balancer) == 0
    error_message = "La salida HTTPS se limita a la VPC y a S3, y no hay balanceador si no se indica."
  }
}

run "behind_alb_with_secrets" {
  command = apply

  variables {
    source_security_group_id = "sg-0aaaaaaaaaaaaaaaa"
    target_group_arn         = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/poc-web-tg/1234567890abcdef"
    secrets                  = { DB_PASSWORD = "arn:aws:secretsmanager:us-east-1:123456789012:secret:poc-db-AbCdEf" }
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.source[0].referenced_security_group_id == "sg-0aaaaaaaaaaaaaaaa" && aws_vpc_security_group_ingress_rule.source[0].from_port == 8080
    error_message = "Solo el grupo del ALB llega al puerto del contenedor."
  }

  assert {
    condition     = one(aws_ecs_service.this.load_balancer).container_port == 8080
    error_message = "El servicio se registra en el grupo de destinos."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.execution_secrets[0].policy).Statement[0].Resource[0] == "arn:aws:secretsmanager:us-east-1:123456789012:secret:poc-db-AbCdEf" && jsondecode(aws_ecs_task_definition.this.container_definitions)[0].secrets[0].name == "DB_PASSWORD"
    error_message = "El rol de ejecución lee solo los secretos declarados y los inyecta en el contenedor."
  }
}

run "explicit_nat_egress" {
  command = apply

  variables {
    egress_cidr_blocks = ["0.0.0.0/0"]
  }

  assert {
    condition     = keys(aws_vpc_security_group_egress_rule.https) == ["0.0.0.0/0"]
    error_message = "La salida a Internet solo existe si el consumidor la pide."
  }
}

run "rejects_latest" {
  command = plan

  variables {
    image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/poc/api:latest"
  }

  expect_failures = [var.image]
}
