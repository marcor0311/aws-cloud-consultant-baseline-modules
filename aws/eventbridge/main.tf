resource "aws_cloudwatch_event_bus" "this" {
  name = var.bus_name
  tags = var.tags
}

resource "aws_cloudwatch_event_archive" "this" {
  count            = var.archive_retention_days > 0 ? 1 : 0
  name             = substr("${var.bus_name}-archive", 0, 48)
  event_source_arn = aws_cloudwatch_event_bus.this.arn
  retention_days   = var.archive_retention_days
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each       = var.rules
  name           = each.key
  description    = each.value.description
  event_bus_name = aws_cloudwatch_event_bus.this.name
  event_pattern  = each.value.event_pattern
  tags           = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each       = var.rules
  rule           = aws_cloudwatch_event_rule.this[each.key].name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  target_id      = each.value.target_type
  arn            = each.value.target_arn

  retry_policy {
    maximum_event_age_in_seconds = var.maximum_event_age_seconds
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = var.dead_letter_queue_arn
  }
}

resource "aws_lambda_permission" "rules" {
  for_each      = { for name, rule in var.rules : name => rule if rule.target_type == "lambda" }
  statement_id  = "eventbridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.target_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this[each.key].arn
}
