resource "aws_dynamodb_table" "this" {
  name                        = var.table_name
  billing_mode                = var.billing_mode
  read_capacity               = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity              = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key                    = var.partition_key.name
  range_key                   = var.sort_key == null ? null : var.sort_key.name
  deletion_protection_enabled = var.deletion_protection_enabled
  tags                        = var.tags

  dynamic "attribute" {
    for_each = concat([var.partition_key], var.sort_key == null ? [] : [var.sort_key])
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled                 = true
    recovery_period_in_days = 35
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute_name == null ? [] : [var.ttl_attribute_name]
    content {
      attribute_name = ttl.value
      enabled        = true
    }
  }

  dynamic "on_demand_throughput" {
    for_each = var.on_demand_max_read_request_units != null || var.on_demand_max_write_request_units != null ? [1] : []
    content {
      max_read_request_units  = var.on_demand_max_read_request_units
      max_write_request_units = var.on_demand_max_write_request_units
    }
  }
}
