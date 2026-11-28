mock_provider "aws" {}

variables {
  name = "poc/api"
}

run "private_defaults" {
  command = apply

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE" && aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push
    error_message = "Las etiquetas son inmutables y cada imagen se escanea al publicarse."
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "AES256" && aws_ecr_repository.this.force_delete == false
    error_message = "Por defecto cifra con AES-256 y no borra repositorios con imágenes."
  }

  assert {
    condition = (
      jsondecode(aws_ecr_lifecycle_policy.this.policy).rules[0].selection.tagStatus == "untagged" &&
      jsondecode(aws_ecr_lifecycle_policy.this.policy).rules[0].selection.countNumber == 7 &&
      jsondecode(aws_ecr_lifecycle_policy.this.policy).rules[1].selection.countNumber == 30
    )
    error_message = "Expiran las imágenes sin etiqueta a los siete días y se conservan las 30 más recientes."
  }

  assert {
    condition     = length(aws_ecr_repository_policy.pull) == 0
    error_message = "Sin principales externos no hay política de repositorio."
  }
}

run "kms_and_cross_account" {
  command = apply

  variables {
    kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
    pull_principal_arns = ["arn:aws:iam::210987654321:root"]
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "KMS"
    error_message = "Con clave indicada se cifra con KMS."
  }

  assert {
    condition     = jsondecode(aws_ecr_repository_policy.pull[0].policy).Statement[0].Principal.AWS[0] == "arn:aws:iam::210987654321:root" && !contains(jsondecode(aws_ecr_repository_policy.pull[0].policy).Statement[0].Action, "ecr:PutImage")
    error_message = "La cuenta externa solo puede descargar."
  }
}

run "rejects_uppercase" {
  command = plan

  variables {
    name = "POC/Api"
  }

  expect_failures = [var.name]
}
