mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:123456789012:poc-events"
      url = "https://sqs.us-east-1.amazonaws.com/123456789012/poc-events"
    }
  }
}

override_resource {
  target = aws_sqs_queue.dead_letter
  values = {
    arn = "arn:aws:sqs:us-east-1:123456789012:poc-events-dlq"
    url = "https://sqs.us-east-1.amazonaws.com/123456789012/poc-events-dlq"
  }
}

variables {
  name = "poc-events"
}

run "standard_defaults" {
  command = apply

  assert {
    condition     = aws_sqs_queue.this.fifo_queue == false && aws_sqs_queue.dead_letter.fifo_queue == false
    error_message = "La cola de origen y su DLQ deben ser Standard."
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled && aws_sqs_queue.dead_letter.sqs_managed_sse_enabled
    error_message = "Las dos colas se cifran con SSE-SQS por defecto."
  }

  assert {
    condition     = aws_sqs_queue.this.visibility_timeout_seconds == 60 && aws_sqs_queue.this.receive_wait_time_seconds == 20 && aws_sqs_queue.dead_letter.message_retention_seconds > aws_sqs_queue.this.message_retention_seconds
    error_message = "La cola de origen conserva un minuto de visibilidad y espera larga. La DLQ retiene mensajes más tiempo."
  }

  assert {
    condition = (
      jsondecode(aws_sqs_queue_redrive_policy.this.redrive_policy).deadLetterTargetArn == output.dead_letter_queue_arn &&
      jsondecode(aws_sqs_queue_redrive_policy.this.redrive_policy).maxReceiveCount == 5 &&
      jsondecode(aws_sqs_queue_redrive_allow_policy.dead_letter.redrive_allow_policy).redrivePermission == "byQueue" &&
      jsondecode(aws_sqs_queue_redrive_allow_policy.dead_letter.redrive_allow_policy).sourceQueueArns[0] == output.queue_arn
    )
    error_message = "La DLQ recibe únicamente de la cola autorizada después del número previsto de intentos."
  }

  assert {
    condition = (
      length(jsondecode(aws_sqs_queue_policy.this.policy).Statement) == 1 &&
      jsondecode(aws_sqs_queue_policy.this.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false" &&
      jsondecode(aws_sqs_queue_policy.dead_letter.policy).Statement[0].Effect == "Deny"
    )
    error_message = "Ambas colas bloquean tráfico sin TLS y los servicios requieren una autorización explícita."
  }
}

run "standard_with_s3" {
  command = apply

  variables {
    s3_source = {
      bucket_arn = "arn:aws:s3:::poc-events-inbound"
      account_id = "123456789012"
    }
  }

  assert {
    condition = (
      jsondecode(aws_sqs_queue_policy.this.policy).Statement[1].Principal.Service == "s3.amazonaws.com" &&
      jsondecode(aws_sqs_queue_policy.this.policy).Statement[1].Action == "sqs:SendMessage" &&
      jsondecode(aws_sqs_queue_policy.this.policy).Statement[1].Condition.ArnEquals["aws:SourceArn"] == var.s3_source.bucket_arn &&
      jsondecode(aws_sqs_queue_policy.this.policy).Statement[1].Condition.StringEquals["aws:SourceAccount"] == var.s3_source.account_id &&
      length(jsondecode(aws_sqs_queue_policy.dead_letter.policy).Statement) == 1
    )
    error_message = "El bucket y su cuenta exactos se autorizan como productores de la cola principal."
  }
}

run "customer_encryption" {
  command = plan

  variables {
    kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/1a234567-89ab-cdef-0123-456789abcdef"
    max_receive_count = 3
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == var.kms_key_arn && aws_sqs_queue.dead_letter.kms_master_key_id == var.kms_key_arn
    error_message = "Ambas colas deben usar la misma clave KMS seleccionada."
  }
}

run "fifo_name" {
  command = plan

  variables {
    name = "poc.fifo"
  }

  expect_failures = [var.name]
}

run "invalid_visibility" {
  command = plan

  variables {
    visibility_timeout_seconds = 20.5
  }

  expect_failures = [var.visibility_timeout_seconds]
}

run "invalid_retries" {
  command = plan

  variables {
    max_receive_count = 0
  }

  expect_failures = [var.max_receive_count]
}

run "scope_s3_source" {
  command = plan

  variables {
    s3_source = {
      bucket_arn = "arn:aws:s3:::poc-*"
      account_id = "123456789012"
    }
  }

  expect_failures = [var.s3_source]
}

run "kms_alias_unsupported" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:alias/aws/sqs"
  }

  expect_failures = [var.kms_key_arn]
}
