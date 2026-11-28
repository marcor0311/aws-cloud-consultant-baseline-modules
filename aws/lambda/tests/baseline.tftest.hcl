mock_provider "aws" {}

variables {
  function_name  = "baseline-example"
  role_arn       = "arn:aws:iam::123456789012:role/baseline-execution"
  log_group_name = "/aws/lambda/baseline-example"
  filename       = "tests/baseline.tftest.hcl"
  handler        = "handler.main"
  runtime        = "python3.12"
  tags           = { Project = "baseline-tests" }
}

run "zip_with_external_dependencies" {
  command = plan

  assert {
    condition = (
      aws_lambda_function.this.package_type == "Zip" &&
      aws_lambda_function.this.architectures[0] == "x86_64" &&
      aws_lambda_function.this.source_code_hash == filebase64sha256(var.filename) &&
      aws_lambda_function.this.role == var.role_arn &&
      aws_lambda_function.this.logging_config[0].log_group == var.log_group_name &&
      aws_lambda_function.this.memory_size == 128 &&
      aws_lambda_function.this.timeout == 30 &&
      output.event_source_mapping_uuid == null
    )
    error_message = "El perfil ZIP debe usar el rol y grupo externos, calcular el hash y omitir el mapeo sin cola."
  }
}

run "sqs_mapping_with_partial_failures" {
  command = plan

  variables {
    source_code_hash = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    sqs_event_source = {
      queue_arn                          = "arn:aws:sqs:us-east-1:123456789012:baseline"
      visibility_timeout_seconds         = 185
      batch_size                         = 15
      maximum_batching_window_in_seconds = 5
    }
  }

  assert {
    condition = (
      aws_lambda_function.this.source_code_hash == var.source_code_hash &&
      aws_lambda_event_source_mapping.sqs[0].event_source_arn == var.sqs_event_source.queue_arn &&
      aws_lambda_event_source_mapping.sqs[0].batch_size == 15 &&
      aws_lambda_event_source_mapping.sqs[0].maximum_batching_window_in_seconds == 5 &&
      contains(aws_lambda_event_source_mapping.sqs[0].function_response_types, "ReportBatchItemFailures")
    )
    error_message = "El mapeo debe usar la cola y el lote indicados con respuesta parcial de errores."
  }
}

run "reject_short_visibility" {
  command = plan

  variables {
    sqs_event_source = {
      queue_arn                          = "arn:aws:sqs:us-east-1:123456789012:baseline"
      visibility_timeout_seconds         = 180
      maximum_batching_window_in_seconds = 1
    }
  }

  expect_failures = [aws_lambda_event_source_mapping.sqs[0]]
}

run "reject_large_batch_without_window" {
  command = plan

  variables {
    sqs_event_source = {
      queue_arn                  = "arn:aws:sqs:us-east-1:123456789012:baseline"
      visibility_timeout_seconds = 180
      batch_size                 = 11
    }
  }

  expect_failures = [var.sqs_event_source]
}

run "reject_fifo" {
  command = plan

  variables {
    sqs_event_source = {
      queue_arn                  = "arn:aws:sqs:us-east-1:123456789012:baseline.fifo"
      visibility_timeout_seconds = 180
    }
  }

  expect_failures = [var.sqs_event_source]
}
