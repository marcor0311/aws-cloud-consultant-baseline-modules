resource "aws_sqs_queue" "this" {
  name                       = var.name
  fifo_queue                 = false
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = var.kms_key_arn == null ? true : null
  kms_master_key_id          = var.kms_key_arn
  tags                       = var.tags
}

resource "aws_sqs_queue" "dead_letter" {
  name                      = "${var.name}-dlq"
  fifo_queue                = false
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 20
  sqs_managed_sse_enabled   = var.kms_key_arn == null ? true : null
  kms_master_key_id         = var.kms_key_arn
  tags                      = var.tags
}

resource "aws_sqs_queue_redrive_allow_policy" "dead_letter" {
  queue_url = aws_sqs_queue.dead_letter.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

resource "aws_sqs_queue_redrive_policy" "this" {
  queue_url = aws_sqs_queue.this.url
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = var.max_receive_count
  })

  depends_on = [aws_sqs_queue_redrive_allow_policy.dead_letter]
}

locals {
  tls_condition = {
    Bool = {
      "aws:SecureTransport"       = "false"
      "aws:PrincipalIsAWSService" = "false"
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.this.arn
        Condition = local.tls_condition
      }],
      var.s3_source == null ? [] : [{
        Sid       = "AllowS3Source"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.this.arn
        Condition = {
          ArnEquals    = { "aws:SourceArn" = var.s3_source.bucket_arn }
          StringEquals = { "aws:SourceAccount" = var.s3_source.account_id }
        }
      }]
    )
  })
}

resource "aws_sqs_queue_policy" "dead_letter" {
  queue_url = aws_sqs_queue.dead_letter.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "sqs:*"
      Resource  = aws_sqs_queue.dead_letter.arn
      Condition = local.tls_condition
    }]
  })
}
