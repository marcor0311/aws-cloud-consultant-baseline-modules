mock_provider "aws" {
  mock_resource "aws_db_instance" {
    defaults = {
      address            = "poc-db.abc123.us-east-1.rds.amazonaws.com"
      resource_id        = "db-ABCDEFGHIJKLMNOP"
      master_user_secret = [{ secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds!db-AbCdEf", kms_key_id = "alias/aws/secretsmanager", secret_status = "active" }]
    }
  }
}

variables {
  identifier                = "poc-db"
  vpc_id                    = "vpc-0123456789abcdef0"
  subnet_ids                = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  client_security_group_ids = ["sg-0aaaaaaaaaaaaaaaa"]
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = aws_db_instance.this.storage_encrypted && aws_db_instance.this.publicly_accessible == false && aws_db_instance.this.manage_master_user_password
    error_message = "Almacenamiento cifrado, sin acceso público y contraseña maestra gestionada por Secrets Manager."
  }

  assert {
    condition     = one([for parameter in aws_db_parameter_group.this.parameter : parameter.value if parameter.name == "rds.force_ssl"]) == "1"
    error_message = "Las conexiones exigen TLS."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection && aws_db_instance.this.skip_final_snapshot == false && aws_db_instance.this.final_snapshot_identifier == "poc-db-final"
    error_message = "Por defecto se protege contra borrado y se toma una copia final."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 7 && aws_db_instance.this.iam_database_authentication_enabled && aws_db_instance.this.allow_major_version_upgrade == false
    error_message = "Siete días de copias, autenticación IAM y sin saltos de versión mayor automáticos."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.clients["sg-0aaaaaaaaaaaaaaaa"].from_port == 5432 && length(aws_vpc_security_group_ingress_rule.clients) == 1
    error_message = "Solo los grupos cliente llegan al puerto 5432."
  }

  assert {
    condition     = aws_db_instance.this.multi_az == false && aws_db_parameter_group.this.family == "postgres17"
    error_message = "Por defecto PostgreSQL 17 en una zona."
  }
}

run "multi_az_with_kms" {
  command = apply

  variables {
    multi_az    = true
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = aws_db_instance.this.multi_az && aws_db_instance.this.kms_key_id == var.kms_key_arn && aws_db_instance.this.master_user_secret_kms_key_id == var.kms_key_arn
    error_message = "Multi-AZ cifra almacenamiento y secreto con la clave indicada."
  }
}

run "rejects_one_subnet" {
  command = plan

  variables {
    subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_no_backups" {
  command = plan

  variables {
    backup_retention_days = 0
  }

  expect_failures = [var.backup_retention_days]
}
