mock_provider "aws" {}

variables {
  table_name  = "baseline-test-table"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  tags = {
    Project     = "baseline-tests"
    Environment = "test"
    Owner       = "platform"
    CostCenter  = "engineering"
  }
}

run "on_demand_secure_defaults" {
  command = apply
  assert {
    condition = (
      aws_dynamodb_table.this.billing_mode == "PAY_PER_REQUEST" &&
      aws_dynamodb_table.this.deletion_protection_enabled &&
      one(aws_dynamodb_table.this.point_in_time_recovery).enabled &&
      one(aws_dynamodb_table.this.server_side_encryption).kms_key_arn == var.kms_key_arn
    )
    error_message = "On-demand debe conservar recuperación, cifrado y protección contra borrado."
  }
}

run "on_demand_with_limits_and_ttl" {
  command = apply
  variables {
    on_demand_max_read_request_units  = 1000
    on_demand_max_write_request_units = 500
    ttl_attribute_name                = "expires_at"
  }
  assert {
    condition = (
      one(aws_dynamodb_table.this.on_demand_throughput).max_read_request_units == 1000 &&
      one(aws_dynamodb_table.this.on_demand_throughput).max_write_request_units == 500 &&
      one(aws_dynamodb_table.this.ttl).attribute_name == "expires_at"
    )
    error_message = "Los límites y TTL deben corresponder a los parámetros del perfil."
  }
}

run "provisioned_capacity" {
  command = apply
  variables {
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 5
  }
  assert {
    condition = (
      aws_dynamodb_table.this.billing_mode == "PROVISIONED" &&
      aws_dynamodb_table.this.read_capacity == 10 &&
      aws_dynamodb_table.this.write_capacity == 5
    )
    error_message = "La capacidad aprovisionada debe usar las RCU/WCU indicadas."
  }
}

run "partition_only_table" {
  command = apply
  variables {
    partition_key = { name = "account_id", type = "S" }
    sort_key      = null
  }
  assert {
    condition     = length(aws_dynamodb_table.this.attribute) == 1 && aws_dynamodb_table.this.hash_key == "account_id"
    error_message = "La tabla sin sort key debe declarar solamente su clave de partición."
  }
}

run "reject_provisioned_without_capacity" {
  command = plan
  variables {
    billing_mode = "PROVISIONED"
  }
  expect_failures = [var.read_capacity, var.write_capacity]
}

run "reject_capacity_in_on_demand" {
  command = plan
  variables {
    read_capacity  = 10
    write_capacity = 5
  }
  expect_failures = [var.read_capacity, var.write_capacity]
}

run "reject_on_demand_limits_in_provisioned" {
  command = plan
  variables {
    billing_mode                     = "PROVISIONED"
    read_capacity                    = 10
    write_capacity                   = 5
    on_demand_max_read_request_units = 100
  }
  expect_failures = [var.on_demand_max_read_request_units]
}

run "reject_duplicate_key_names" {
  command = plan
  variables {
    sort_key = { name = "pk", type = "S" }
  }
  expect_failures = [var.sort_key]
}

run "reject_ttl_on_primary_key" {
  command = plan
  variables {
    ttl_attribute_name = "pk"
  }
  expect_failures = [var.ttl_attribute_name]
}

run "reject_missing_tags" {
  command = plan
  variables {
    tags = { Environment = "test" }
  }
  expect_failures = [var.tags]
}
