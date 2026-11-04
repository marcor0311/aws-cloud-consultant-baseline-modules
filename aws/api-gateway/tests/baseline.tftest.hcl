mock_provider "aws" {
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "testapi123"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:testapi123"
    }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/test-api"
    }
  }
}

variables {
  name                = "test-api"
  lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:test-handler"
  log_kms_key_arn     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  routes              = ["GET /items", "POST /items"]
  tags = {
    Project     = "baseline-tests"
    Environment = "test"
    Owner       = "platform"
    CostCenter  = "engineering"
  }
}

run "iam_and_logging_defaults" {
  command = apply
  assert {
    condition = alltrue([
      for route in aws_apigatewayv2_route.this : route.authorization_type == "AWS_IAM"
    ]) && length(aws_apigatewayv2_authorizer.jwt) == 0
    error_message = "Todas las rutas deben exigir IAM por defecto."
  }
  assert {
    condition = (
      aws_cloudwatch_log_group.access.retention_in_days == 90 &&
      endswith(aws_cloudwatch_log_group.access.name, "/default") &&
      aws_cloudwatch_log_group.access.kms_key_id == var.log_kms_key_arn &&
      one(aws_apigatewayv2_stage.this.default_route_settings).throttling_rate_limit == 100 &&
      one(aws_apigatewayv2_stage.this.default_route_settings).throttling_burst_limit == 200
    )
    error_message = "Logs y throttling deben conservar los controles del baseline."
  }
  assert {
    condition = (
      aws_lambda_permission.api_gateway.source_arn == "arn:aws:execute-api:us-east-1:123456789012:testapi123/$default/*/*" &&
      aws_lambda_permission.api_gateway.function_name == var.lambda_function_arn
    )
    error_message = "El permiso Lambda debe limitarse a esta API, stage y función."
  }
}

run "jwt_authorization" {
  command = apply
  variables {
    authorization_type = "JWT"
    jwt = {
      issuer   = "https://identity.example.com"
      audience = ["consulting-api"]
    }
    authorization_scopes = ["items:read"]
  }
  assert {
    condition = alltrue([
      for route in aws_apigatewayv2_route.this :
      route.authorization_type == "JWT" && route.authorizer_id == aws_apigatewayv2_authorizer.jwt[0].id &&
      contains(route.authorization_scopes, "items:read")
    ])
    error_message = "Las rutas JWT deben usar el authorizer y los scopes configurados."
  }
  assert {
    condition     = one(aws_apigatewayv2_authorizer.jwt[0].jwt_configuration).issuer == "https://identity.example.com"
    error_message = "El authorizer debe usar el emisor configurado."
  }
}

run "custom_stage_and_limits" {
  command = apply
  variables {
    stage_name                = "prod"
    throttling_rate_limit     = 2000
    throttling_burst_limit    = 5000
    access_log_retention_days = 365
  }
  assert {
    condition = (
      aws_apigatewayv2_stage.this.name == "prod" &&
      one(aws_apigatewayv2_stage.this.default_route_settings).throttling_rate_limit == 2000 &&
      aws_cloudwatch_log_group.access.retention_in_days == 365 &&
      endswith(aws_lambda_permission.api_gateway.source_arn, "/prod/*/*")
    )
    error_message = "El stage y sus límites deben conservar la configuración explícita."
  }
}

run "reject_anonymous_routes" {
  command = plan
  variables {
    authorization_type = "NONE"
  }
  expect_failures = [var.authorization_type]
}

run "reject_jwt_without_issuer" {
  command = plan
  variables {
    authorization_type = "JWT"
  }
  expect_failures = [var.jwt]
}

run "reject_insecure_jwt_issuer" {
  command = plan
  variables {
    authorization_type = "JWT"
    jwt                = { issuer = "http://identity.example.com", audience = ["api"] }
  }
  expect_failures = [var.jwt]
}

run "reject_scopes_without_jwt" {
  command = plan
  variables {
    authorization_scopes = ["items:read"]
  }
  expect_failures = [var.authorization_scopes]
}

run "reject_invalid_routes" {
  command = plan
  variables {
    routes = ["NOT_A_ROUTE"]
  }
  expect_failures = [var.routes]
}

run "reject_missing_tags" {
  command = plan
  variables {
    tags = { Environment = "test" }
  }
  expect_failures = [var.tags]
}
