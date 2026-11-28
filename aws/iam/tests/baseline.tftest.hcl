mock_provider "aws" {}

variables {
  role_name           = "baseline-poc-worker"
  queue_arns          = ["arn:aws:sqs:us-east-1:123456789012:baseline-poc-events"]
  log_group_arns      = ["arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/baseline-poc-worker:*"]
  dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:123456789012:table/baseline-poc-results"]
  tags                = { Environment = "test" }
}

run "queue_worker_limits_trust_and_permissions" {
  command = plan

  assert {
    condition = jsondecode(aws_iam_role.execution.assume_role_policy).Statement == jsondecode(jsonencode([{
      Sid       = "LambdaExecution"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]))
    error_message = "El rol debe confiar exclusivamente en Lambda."
  }

  assert {
    condition = tomap({
      for statement in jsondecode(aws_iam_role_policy.execution.policy).Statement :
      statement.Sid => {
        Effect   = statement.Effect
        Action   = toset(statement.Action)
        Resource = toset(statement.Resource)
      }
      }) == tomap({
      ConsumeQueue = {
        Effect   = "Allow"
        Action   = toset(["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"])
        Resource = var.queue_arns
      }
      WriteLogs = {
        Effect   = "Allow"
        Action   = toset(["logs:CreateLogStream", "logs:PutLogEvents"])
        Resource = toset(["arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/baseline-poc-worker:log-stream:*"])
      }
      WriteItems = {
        Effect   = "Allow"
        Action   = toset(["dynamodb:PutItem"])
        Resource = var.dynamodb_table_arns
      }
    })
    error_message = "La política debe permitir solo las operaciones de la cola, streams y tablas suministradas."
  }
}

run "encrypted_worker_adds_exact_optional_permissions" {
  command = plan

  variables {
    log_group_arns = [
      "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/baseline-poc-worker",
      "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/baseline-poc-worker:*",
    ]
    s3_object_arns = ["arn:aws:s3:::baseline-poc-assets-example/incoming/*"]
    kms_key_arns   = ["arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000001"]
  }

  assert {
    condition = tomap({
      for statement in jsondecode(aws_iam_role_policy.execution.policy).Statement :
      statement.Sid => {
        Effect   = statement.Effect
        Action   = toset(statement.Action)
        Resource = toset(statement.Resource)
      } if contains(["ReadObjects", "DecryptData"], statement.Sid)
      }) == tomap({
      ReadObjects = {
        Effect   = "Allow"
        Action   = toset(["s3:GetObject"])
        Resource = var.s3_object_arns
      }
      DecryptData = {
        Effect   = "Allow"
        Action   = toset(["kms:Decrypt"])
        Resource = var.kms_key_arns
      }
    })
    error_message = "El perfil cifrado debe añadir únicamente lectura de los objetos y descifrado con las claves indicadas."
  }

  assert {
    condition = one([
      for statement in jsondecode(aws_iam_role_policy.execution.policy).Statement :
      length(statement.Resource) if statement.Sid == "WriteLogs"
    ]) == 1
    error_message = "Dos formas del mismo ARN de grupo deben generar un solo ARN de streams."
  }
}

run "rejects_invalid_name_and_overbroad_resource_arns" {
  command = plan

  variables {
    role_name           = "invalid/role"
    queue_arns          = ["arn:aws:sqs:us-east-1:123456789012:*"]
    log_group_arns      = ["arn:aws:logs:us-east-1:123456789012:log-group:*"]
    dynamodb_table_arns = ["arn:aws:dynamodb:us-east-1:123456789012:table/*"]
    s3_object_arns      = ["arn:aws:s3:::baseline-poc-assets-example/*"]
    kms_key_arns        = ["arn:aws:kms:us-east-1:123456789012:alias/example"]
  }

  expect_failures = [var.role_name, var.queue_arns, var.log_group_arns, var.dynamodb_table_arns, var.s3_object_arns, var.kms_key_arns]
}

run "requires_destinations_for_the_worker" {
  command = plan

  variables {
    queue_arns          = []
    log_group_arns      = []
    dynamodb_table_arns = []
  }

  expect_failures = [var.queue_arns, var.log_group_arns, var.dynamodb_table_arns]
}
