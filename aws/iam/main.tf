locals {
  permissions = concat(
    [
      {
        Sid      = "ConsumeQueue"
        Effect   = "Allow"
        Action   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
        Resource = sort(tolist(var.queue_arns))
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = sort(distinct([
          for arn in var.log_group_arns : "${trimsuffix(arn, ":*")}:log-stream:*"
        ]))
      },
      {
        Sid      = "WriteItems"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = sort(tolist(var.dynamodb_table_arns))
      },
    ],
    length(var.s3_object_arns) == 0 ? [] : [
      {
        Sid      = "ReadObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = sort(tolist(var.s3_object_arns))
      },
    ],
    length(var.kms_key_arns) == 0 ? [] : [
      {
        Sid      = "DecryptData"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = sort(tolist(var.kms_key_arns))
      },
    ],
  )
}

resource "aws_iam_role" "execution" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "LambdaExecution"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "execution" {
  name = "lambda-execution"
  role = aws_iam_role.execution.name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.permissions
  })
}
