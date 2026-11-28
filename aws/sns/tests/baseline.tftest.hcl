mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-east-1:123456789012:poc-orders" }
  }
}

variables {
  name        = "poc-orders"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
}

run "topic_defaults" {
  command = apply

  assert {
    condition     = aws_sns_topic.this.kms_master_key_id == var.kms_key_arn
    error_message = "El tópico se cifra con la clave del cliente."
  }

  assert {
    condition = (
      length(jsondecode(aws_sns_topic_policy.this.policy).Statement) == 2 &&
      jsondecode(aws_sns_topic_policy.this.policy).Statement[0].Principal.AWS == "arn:aws:iam::123456789012:root" &&
      jsondecode(aws_sns_topic_policy.this.policy).Statement[1].Effect == "Deny"
    )
    error_message = "Solo la cuenta propietaria publica y se rechaza tráfico sin TLS."
  }
}

run "service_publisher_and_queues" {
  command = apply

  variables {
    publisher_services = [{ service = "events.amazonaws.com", source_arn = "arn:aws:events:us-east-1:123456789012:rule/poc-orders" }]
    sqs_subscriptions  = { billing = "arn:aws:sqs:us-east-1:123456789012:poc-billing" }
  }

  assert {
    condition     = jsondecode(aws_sns_topic_policy.this.policy).Statement[2].Condition.ArnEquals["aws:SourceArn"] == "arn:aws:events:us-east-1:123456789012:rule/poc-orders"
    error_message = "El servicio publicador queda limitado a su ARN de origen."
  }

  assert {
    condition     = aws_sns_topic_subscription.sqs["billing"].raw_message_delivery && aws_sns_topic_subscription.sqs["billing"].protocol == "sqs"
    error_message = "Las colas reciben el mensaje en bruto."
  }
}

run "rejects_kms_alias" {
  command = plan

  variables {
    kms_key_arn = "alias/aws/sns"
  }

  expect_failures = [var.kms_key_arn]
}

run "rejects_unscoped_service" {
  command = plan

  variables {
    publisher_services = [{ service = "events.amazonaws.com", source_arn = "*" }]
  }

  expect_failures = [var.publisher_services]
}
