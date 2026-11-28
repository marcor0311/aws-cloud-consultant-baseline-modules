resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  role                           = var.role_arn
  package_type                   = "Zip"
  architectures                  = ["x86_64"]
  filename                       = var.filename
  source_code_hash               = var.source_code_hash == null ? filebase64sha256(var.filename) : var.source_code_hash
  handler                        = var.handler
  runtime                        = var.runtime
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  tags                           = var.tags

  environment {
    variables = var.environment_variables
  }

  logging_config {
    log_format = "Text"
    log_group  = var.log_group_name
  }
}

resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.sqs_event_source == null ? 0 : 1

  function_name                      = aws_lambda_function.this.arn
  event_source_arn                   = var.sqs_event_source.queue_arn
  batch_size                         = var.sqs_event_source.batch_size
  maximum_batching_window_in_seconds = var.sqs_event_source.maximum_batching_window_in_seconds
  function_response_types            = ["ReportBatchItemFailures"]
  enabled                            = true
  tags                               = var.tags

  lifecycle {
    precondition {
      condition = (
        var.sqs_event_source.visibility_timeout_seconds >=
        6 * var.timeout + var.sqs_event_source.maximum_batching_window_in_seconds
      )
      error_message = "La visibilidad de SQS debe cubrir al menos seis veces el timeout de Lambda más la ventana de lote."
    }
  }
}
