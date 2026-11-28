mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.0.0.0/16" }
  }
  mock_resource "aws_lb" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/poc-web/1234567890abcdef" }
  }
  mock_resource "aws_lb_target_group" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/poc-web-tg/1234567890abcdef" }
  }
}

variables {
  name            = "poc-web"
  vpc_id          = "vpc-0123456789abcdef0"
  subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"
}

run "https_defaults" {
  command = apply

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields && aws_lb.this.enable_deletion_protection && aws_lb.this.internal == false
    error_message = "El ALB descarta cabeceras inválidas y tiene protección contra borrado."
  }

  assert {
    condition     = aws_lb_listener.https.ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06" && aws_lb_listener.https.default_action[0].type == "forward"
    error_message = "HTTPS usa la política TLS 1.2 o superior y envía al grupo de destinos."
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].redirect[0].protocol == "HTTPS" && aws_lb_listener.http.default_action[0].redirect[0].status_code == "HTTP_301"
    error_message = "HTTP redirige permanentemente a HTTPS."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.targets[0].cidr_ipv4 == "10.0.0.0/16" && aws_vpc_security_group_egress_rule.targets[0].from_port == 8080
    error_message = "La salida se limita al puerto de destino dentro de la VPC."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.listener) == 2 && aws_lb_target_group.this.target_type == "ip"
    error_message = "Entran 80 y 443 desde el rango indicado y los destinos son IP para Fargate."
  }
}

run "restricted_ingress" {
  command = apply

  variables {
    internal            = true
    ingress_cidr_blocks = ["10.0.0.0/16", "192.168.0.0/24"]
  }

  assert {
    condition     = aws_lb.this.internal && length(aws_vpc_security_group_ingress_rule.listener) == 4
    error_message = "Un ALB interno acepta ambos puertos desde cada rango indicado."
  }
}

run "existing_security_group" {
  command = apply

  variables {
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_security_group.this) == 0 && length(aws_vpc_security_group_ingress_rule.listener) == 0 && output.security_group_id == "sg-0123456789abcdef0"
    error_message = "Con grupos existentes el módulo no crea uno propio ni reglas."
  }
}

run "rejects_single_subnet" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_certificate_alias" {
  command = plan

  variables {
    certificate_arn = "poc.example.com"
  }

  expect_failures = [var.certificate_arn]
}
