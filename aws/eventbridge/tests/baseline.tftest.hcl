mock_provider "aws" {
  mock_resource "aws_cloudwatch_event_bus" {
    defaults = { arn = "arn:aws:events:us-east-1:123456789012:event-bus/poc-domain" }
  }
  mock_resource "aws_cloudwatch_event_rule" {
    defaults = { arn = "arn:aws:events:us-east-1:123456789012:rule/poc-domain/order-created" }
  }
}

variables {
  bus_name              = "poc-domain"
  dead_letter_queue_arn = "arn:aws:sqs:us-east-1:123456789012:poc-events-dlq"
  rules = {
    order-created = {
      event_pattern = "{\"source\":[\"poc.orders\"]}"
      target_type   = "sqs"
      target_arn    = "arn:aws:sqs:us-east-1:123456789012:poc-orders"
    }
    notify = {
      event_pattern = "{\"source\":[\"poc.orders\"]}"
      target_type   = "lambda"
      target_arn    = "arn:aws:lambda:us-east-1:123456789012:function:poc-notify"
    }
  }
}

run "bus_defaults" {
  command = apply

  assert {
    condition     = alltrue([for target in aws_cloudwatch_event_target.this : target.dead_letter_config[0].arn == var.dead_letter_queue_arn && target.retry_policy[0].maximum_event_age_in_seconds == 3600])
    error_message = "Cada destino reintenta una hora y luego envía a la DLQ."
  }

  assert {
    condition     = aws_cloudwatch_event_archive.this[0].retention_days == 7
    error_message = "Los eventos se archivan siete días para reproducirlos."
  }

  assert {
    condition     = length(aws_lambda_permission.rules) == 1 && aws_lambda_permission.rules["notify"].source_arn == aws_cloudwatch_event_rule.this["notify"].arn
    error_message = "Solo los destinos Lambda reciben permiso, limitado a su regla."
  }

  assert {
    condition     = alltrue([for rule in aws_cloudwatch_event_rule.this : rule.event_bus_name == "poc-domain"])
    error_message = "Las reglas escuchan el bus personalizado."
  }
}

run "no_archive" {
  command = apply

  variables {
    archive_retention_days = 0
  }

  assert {
    condition     = length(aws_cloudwatch_event_archive.this) == 0
    error_message = "Con cero días no se crea archivo."
  }
}

run "rejects_unknown_target" {
  command = plan

  variables {
    rules = {
      bad = { event_pattern = "{}", target_type = "kinesis", target_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/x" }
    }
  }

  expect_failures = [var.rules]
}

run "rejects_default_bus" {
  command = plan

  variables {
    bus_name = "default"
  }

  expect_failures = [var.bus_name]
}
