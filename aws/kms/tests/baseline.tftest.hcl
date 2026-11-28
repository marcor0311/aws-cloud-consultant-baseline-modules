mock_provider "aws" {}

variables {
  alias_name = "alias/poc-baseline"
}

run "iam_delegation" {
  command = plan

  assert {
    condition     = aws_kms_key.this.enable_key_rotation && aws_kms_key.this.deletion_window_in_days == 30 && aws_kms_key.this.bypass_policy_lockout_safety_check == false
    error_message = "Los valores predeterminados requieren rotación, ventana de 30 días y protección de la política."
  }

  assert {
    condition     = aws_kms_key.this.customer_master_key_spec == "SYMMETRIC_DEFAULT" && aws_kms_key.this.key_usage == "ENCRYPT_DECRYPT" && aws_kms_key.this.multi_region == false
    error_message = "El baseline debe crear una clave simétrica de cifrado regional."
  }

  assert {
    condition     = var.policy_json == null && output.alias_name == "alias/poc-baseline"
    error_message = "El perfil delegado deja la política predeterminada de AWS y publica el alias solicitado."
  }
}

run "custom_policy" {
  command = plan

  variables {
    deletion_window_in_days = 14
    tags                    = { Environment = "poc" }
    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::123456789012:root" }
        Action    = "kms:*"
        Resource  = "*"
      }]
    })
  }

  assert {
    condition     = aws_kms_key.this.policy == var.policy_json && aws_kms_key.this.deletion_window_in_days == 14 && aws_kms_key.this.tags["Environment"] == "poc"
    error_message = "La clave respeta la política, las etiquetas y la ventana solicitadas."
  }
}

run "reserved_alias" {
  command = plan

  variables {
    alias_name = "alias/aws/reserved"
  }

  expect_failures = [var.alias_name]
}

run "short_deletion_window" {
  command = plan

  variables {
    deletion_window_in_days = 6
  }

  expect_failures = [var.deletion_window_in_days]
}

run "malformed_policy" {
  command = plan

  variables {
    policy_json = "[]"
  }

  expect_failures = [var.policy_json]
}
