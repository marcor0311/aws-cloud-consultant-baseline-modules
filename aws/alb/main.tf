data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  create_security_group = var.security_group_ids == null
  security_group_ids    = local.create_security_group ? aws_security_group.this[*].id : var.security_group_ids
}

resource "aws_security_group" "this" {
  count       = local.create_security_group ? 1 : 0
  name        = "${var.name}-alb"
  description = "Entrada HTTP y HTTPS del balanceador ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "listener" {
  for_each          = local.create_security_group ? { for pair in setproduct([80, 443], var.ingress_cidr_blocks) : "${pair[0]}-${pair[1]}" => pair } : {}
  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "tcp"
  from_port         = each.value[0]
  to_port           = each.value[0]
  cidr_ipv4         = each.value[1]
  description       = each.value[0] == 80 ? "Redirección a HTTPS" : "HTTPS"
}

# La salida se limita al puerto de los destinos dentro de la VPC.
resource "aws_vpc_security_group_egress_rule" "targets" {
  count             = local.create_security_group ? 1 : 0
  security_group_id = aws_security_group.this[0].id
  ip_protocol       = "tcp"
  from_port         = var.target_port
  to_port           = var.target_port
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  description       = "Destinos del balanceador"
}

resource "aws_lb" "this" {
  name                       = var.name
  load_balancer_type         = "application"
  internal                   = var.internal
  subnets                    = var.subnet_ids
  security_groups            = local.security_group_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  desync_mitigation_mode     = "defensive"
  tags                       = var.tags

  dynamic "access_logs" {
    for_each = var.access_logs_bucket == null ? [] : [var.access_logs_bucket]
    content {
      bucket  = access_logs.value
      prefix  = var.name
      enabled = true
    }
  }
}

resource "aws_lb_target_group" "this" {
  name                 = "${var.name}-tg"
  vpc_id               = var.target_type == "lambda" ? null : var.vpc_id
  target_type          = var.target_type
  port                 = var.target_type == "lambda" ? null : var.target_port
  protocol             = var.target_type == "lambda" ? null : "HTTP"
  deregistration_delay = 30
  tags                 = var.tags

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn
  tags              = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  tags              = var.tags

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
