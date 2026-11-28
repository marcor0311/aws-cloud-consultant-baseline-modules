mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/vpc/poc/flow-logs" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/poc-vpc-flow-logs" }
  }
}

variables {
  name               = "poc"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

run "private_defaults" {
  command = apply

  assert {
    condition     = length(aws_subnet.private) == 2 && length(aws_subnet.public) == 2 && length(aws_nat_gateway.this) == 2
    error_message = "Por defecto hay una subred pública, una privada y un NAT por zona."
  }

  assert {
    condition     = alltrue([for subnet in aws_subnet.public : subnet.map_public_ip_on_launch == false])
    error_message = "Las subredes públicas no asignan IP pública automáticamente."
  }

  assert {
    condition     = length(setintersection(toset(aws_subnet.public[*].cidr_block), toset(aws_subnet.private[*].cidr_block))) == 0
    error_message = "Los rangos públicos y privados no se solapan."
  }

  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0 && length(aws_default_security_group.this.egress) == 0
    error_message = "El grupo de seguridad por defecto queda sin reglas."
  }

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL" && aws_cloudwatch_log_group.flow_logs.retention_in_days == 30
    error_message = "Los Flow Logs registran todo el tráfico con retención de 30 días."
  }

  assert {
    condition     = aws_vpc_endpoint.gateway["s3"].service_name == "com.amazonaws.us-east-1.s3" && length(aws_vpc_endpoint.gateway["dynamodb"].route_table_ids) == 2
    error_message = "S3 y DynamoDB usan endpoints de puerta de enlace en las tablas privadas."
  }
}

run "single_nat" {
  command = apply

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route.private_nat) == 2
    error_message = "Con un solo NAT ambas zonas privadas salen por él."
  }
}

run "isolated" {
  command = apply

  variables {
    internet_egress = false
  }

  assert {
    condition     = length(aws_subnet.public) == 0 && length(aws_internet_gateway.this) == 0 && length(aws_nat_gateway.this) == 0 && length(aws_route.private_nat) == 0
    error_message = "Una VPC aislada no tiene subredes públicas, Internet Gateway ni NAT."
  }
}

run "rejects_one_zone" {
  command = plan

  variables {
    availability_zones = ["us-east-1a"]
  }

  expect_failures = [var.availability_zones]
}

run "rejects_large_cidr" {
  command = plan

  variables {
    cidr_block = "10.0.0.0/8"
  }

  expect_failures = [var.cidr_block]
}
