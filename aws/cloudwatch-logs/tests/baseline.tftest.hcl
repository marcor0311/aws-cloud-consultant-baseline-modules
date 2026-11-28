mock_provider "aws" {}

variables {
  name = "/aws/lambda/baseline-example"
  tags = { Project = "baseline-tests" }
}

run "service_managed_defaults" {
  command = plan

  assert {
    condition = (
      aws_cloudwatch_log_group.this.log_group_class == "STANDARD" &&
      aws_cloudwatch_log_group.this.retention_in_days == 30 &&
      aws_cloudwatch_log_group.this.kms_key_id == null &&
      aws_cloudwatch_log_group.this.tags == var.tags &&
      output.log_group_name == var.name
    )
    error_message = "El perfil predeterminado debe usar clase STANDARD, retención de 30 días y cifrado del servicio."
  }
}

run "customer_managed" {
  command = plan

  variables {
    retention_in_days = 90
    kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-4333-8444-555555555555"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id == var.kms_key_arn && aws_cloudwatch_log_group.this.retention_in_days == 90
    error_message = "La clave y la retención del consumidor deben llegar al grupo."
  }
}

run "reject_unlimited_retention" {
  command = plan

  variables {
    retention_in_days = 0
  }

  expect_failures = [var.retention_in_days]
}

run "reject_kms_alias" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:alias/example"
  }

  expect_failures = [var.kms_key_arn]
}
