resource "aws_kms_key" "this" {
  description                        = var.description
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  key_usage                          = "ENCRYPT_DECRYPT"
  enable_key_rotation                = true
  multi_region                       = false
  deletion_window_in_days            = var.deletion_window_in_days
  bypass_policy_lockout_safety_check = false
  policy                             = var.policy_json
  tags                               = var.tags
}

resource "aws_kms_alias" "this" {
  name          = var.alias_name
  target_key_id = aws_kms_key.this.key_id
}
