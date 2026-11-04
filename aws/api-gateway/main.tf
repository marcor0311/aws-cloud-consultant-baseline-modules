resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = "arn:${split(":", var.lambda_function_arn)[1]}:apigateway:${split(":", var.lambda_function_arn)[3]}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count            = var.authorization_type == "JWT" ? 1 : 0
  api_id           = aws_apigatewayv2_api.this.id
  name             = "jwt"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = var.jwt.issuer
    audience = var.jwt.audience
  }
}

resource "aws_apigatewayv2_route" "this" {
  for_each             = var.routes
  api_id               = aws_apigatewayv2_api.this.id
  route_key            = each.value
  target               = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type   = var.authorization_type
  authorizer_id        = var.authorization_type == "JWT" ? aws_apigatewayv2_authorizer.jwt[0].id : null
  authorization_scopes = var.authorization_type == "JWT" ? var.authorization_scopes : null
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/aws/apigateway/${var.name}/${replace(var.stage_name, "$default", "default")}"
  retention_in_days = var.access_log_retention_days
  kms_key_id        = var.log_kms_key_arn
  tags              = var.tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  tags        = var.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id_prefix = "AllowHttpApi-"
  action              = "lambda:InvokeFunction"
  function_name       = var.lambda_function_arn
  principal           = "apigateway.amazonaws.com"
  source_arn          = "${aws_apigatewayv2_api.this.execution_arn}/${var.stage_name}/*/*"
}
