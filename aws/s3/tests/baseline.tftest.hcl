mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "baseline-test-bucket"
      arn = "arn:aws:s3:::baseline-test-bucket"
    }
  }
}

variables {
  bucket_name = "baseline-test-bucket"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  tags = {
    Project     = "baseline-tests"
    Environment = "test"
    Owner       = "platform"
    CostCenter  = "engineering"
  }
}

run "secure_defaults" {
  command = apply

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "El acceso público debe permanecer bloqueado."
  }
  assert {
    condition = (
      one(aws_s3_bucket_ownership_controls.this.rule).object_ownership == "BucketOwnerEnforced" &&
      !aws_s3_bucket.this.force_destroy
    )
    error_message = "No permitir ACLs ni borrado forzado del contenido."
  }
  assert {
    condition = (
      one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms" &&
      one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_arn
    )
    error_message = "El cifrado debe usar la clave KMS del consumidor."
  }
  assert {
    condition     = one(aws_s3_bucket_versioning.this.versioning_configuration).status == "Enabled"
    error_message = "El versionado debe estar habilitado por defecto."
  }
  assert {
    condition = (
      jsondecode(aws_s3_bucket_policy.require_tls.policy).Statement[0].Effect == "Deny" &&
      jsondecode(aws_s3_bucket_policy.require_tls.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false" &&
      length(jsondecode(aws_s3_bucket_policy.require_tls.policy).Statement[0].Resource) == 2
    )
    error_message = "La política debe denegar HTTP para bucket y objetos."
  }
}

run "retention_and_access_logs" {
  command = apply
  variables {
    expiration_days                    = 14
    noncurrent_version_expiration_days = 30
    access_logs = {
      bucket = "central-access-logs"
      prefix = "applications/"
    }
  }
  assert {
    condition = (
      one(one(aws_s3_bucket_lifecycle_configuration.this[0].rule).expiration).days == 14 &&
      one(one(aws_s3_bucket_lifecycle_configuration.this[0].rule).noncurrent_version_expiration).noncurrent_days == 30
    )
    error_message = "La retención debe reflejar los valores configurados."
  }
  assert {
    condition     = aws_s3_bucket_logging.this[0].target_bucket == "central-access-logs"
    error_message = "Los logs deben dirigirse al destino explícito."
  }
}

run "reject_retention_without_versioning" {
  command = plan
  variables {
    versioning_enabled                 = false
    noncurrent_version_expiration_days = 30
  }
  expect_failures = [var.noncurrent_version_expiration_days]
}

run "reject_invalid_name" {
  command = plan
  variables {
    bucket_name = "INVALID BUCKET"
  }
  expect_failures = [var.bucket_name]
}

run "reject_missing_corporate_tags" {
  command = plan
  variables {
    tags = { Environment = "test" }
  }
  expect_failures = [var.tags]
}

run "reject_kms_alias" {
  command = plan
  variables {
    kms_key_arn = "alias/shared"
  }
  expect_failures = [var.kms_key_arn]
}

run "reject_logging_to_same_bucket" {
  command = plan
  variables {
    access_logs = { bucket = "baseline-test-bucket" }
  }
  expect_failures = [var.access_logs]
}
