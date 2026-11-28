mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/vendedlogs/states/poc-flow" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/poc-flow-sfn" }
  }
}

variables {
  name       = "poc-flow"
  definition = "{\"StartAt\":\"Done\",\"States\":{\"Done\":{\"Type\":\"Succeed\"}}}"
}

run "workflow_defaults" {
  command = apply

  assert {
    condition     = aws_sfn_state_machine.this.type == "STANDARD" && aws_sfn_state_machine.this.tracing_configuration[0].enabled
    error_message = "Flujo Standard con trazas X-Ray."
  }

  assert {
    condition     = aws_sfn_state_machine.this.logging_configuration[0].level == "ERROR" && aws_sfn_state_machine.this.logging_configuration[0].include_execution_data == false
    error_message = "Registra errores sin incluir los datos de la ejecución."
  }

  assert {
    condition     = length(aws_iam_role_policy.lambda) == 0 && length(aws_iam_role_policy.additional) == 0
    error_message = "Sin entradas opcionales el rol solo puede registrar y trazar."
  }
}

run "invokes_functions" {
  command = apply

  variables {
    lambda_function_arns = ["arn:aws:lambda:us-east-1:123456789012:function:poc-validate"]
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.lambda[0].policy).Statement[0].Resource == ["arn:aws:lambda:us-east-1:123456789012:function:poc-validate", "arn:aws:lambda:us-east-1:123456789012:function:poc-validate:*"]
    error_message = "El rol invoca solo las funciones indicadas y sus versiones."
  }
}

run "rejects_invalid_definition" {
  command = plan

  variables {
    definition = "{\"States\":{}}"
  }

  expect_failures = [var.definition]
}
