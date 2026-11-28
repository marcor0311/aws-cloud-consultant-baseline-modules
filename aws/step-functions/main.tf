resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "this" {
  name = "${var.name}-sfn"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

# Step Functions entrega logs a través de CloudWatch Logs delivery, que exige Resource "*".
resource "aws_iam_role_policy" "observability" {
  name = "logs-and-tracing"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery", "logs:GetLogDelivery", "logs:UpdateLogDelivery", "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries", "logs:PutResourcePolicy", "logs:DescribeResourcePolicies", "logs:DescribeLogGroups",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords", "xray:GetSamplingRules", "xray:GetSamplingTargets"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda" {
  count = length(var.lambda_function_arns) > 0 ? 1 : 0
  name  = "invoke-functions"
  role  = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = flatten([for arn in var.lambda_function_arns : [arn, "${arn}:*"]])
    }]
  })
}

resource "aws_iam_role_policy" "additional" {
  count  = var.additional_policy_json == null ? 0 : 1
  name   = "workflow"
  role   = aws_iam_role.this.id
  policy = var.additional_policy_json
}

resource "aws_sfn_state_machine" "this" {
  name       = var.name
  type       = "STANDARD"
  role_arn   = aws_iam_role.this.arn
  definition = var.definition
  tags       = var.tags

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.this.arn}:*"
    level                  = var.log_level
    include_execution_data = false
  }

  tracing_configuration {
    enabled = true
  }

  depends_on = [aws_iam_role_policy.observability, aws_iam_role_policy.lambda, aws_iam_role_policy.additional]
}
