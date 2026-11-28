locals {
  create_security_group = var.security_group_ids == null
  security_group_ids    = local.create_security_group ? aws_security_group.this[*].id : var.security_group_ids
}

resource "aws_db_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-pg${var.engine_version}"
  family = "postgres${var.engine_version}"
  tags   = var.tags

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  count       = local.create_security_group ? 1 : 0
  name        = "${var.identifier}-db"
  description = "PostgreSQL ${var.identifier}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.identifier}-db" })
}

resource "aws_vpc_security_group_ingress_rule" "clients" {
  for_each                     = local.create_security_group ? toset(var.client_security_group_ids) : toset([])
  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Clientes de PostgreSQL"
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  db_name        = var.database_name
  username       = "app_admin"

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = local.security_group_ids
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  port                   = 5432

  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  allow_major_version_upgrade         = false
  backup_retention_period             = var.backup_retention_days
  copy_tags_to_snapshot               = true
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : "${var.identifier}-final"
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  tags                                = var.tags
}
