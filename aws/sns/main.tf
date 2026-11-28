data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "this" {
  name              = var.name
  kms_master_key_id = var.kms_key_arn
  tags              = var.tags
}

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "OwnerAccount"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
          Action    = ["sns:Publish", "sns:Subscribe", "sns:GetTopicAttributes", "sns:ListSubscriptionsByTopic"]
          Resource  = aws_sns_topic.this.arn
        },
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Principal = "*"
          Action    = "sns:Publish"
          Resource  = aws_sns_topic.this.arn
          Condition = { Bool = { "aws:SecureTransport" = "false" } }
        },
      ],
      [for index, item in var.publisher_services : {
        Sid       = "AllowService${index}"
        Effect    = "Allow"
        Principal = { Service = item.service }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.this.arn
        Condition = { ArnEquals = { "aws:SourceArn" = item.source_arn } }
      }]
    )
  })
}

resource "aws_sns_topic_subscription" "sqs" {
  for_each             = var.sqs_subscriptions
  topic_arn            = aws_sns_topic.this.arn
  protocol             = "sqs"
  endpoint             = each.value
  raw_message_delivery = true
}
