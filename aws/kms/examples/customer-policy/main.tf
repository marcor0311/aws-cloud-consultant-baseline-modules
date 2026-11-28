data "aws_partition" "current" {}

data "aws_iam_policy_document" "key" {
  statement {
    sid       = "EnableAccountIAM"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.aws_account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudWatchLogs"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.${data.aws_partition.current.dns_suffix}"]
    }
    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${var.aws_account_id}:log-group:${var.log_group_name}"]
    }
  }
}

module "kms" {
  source      = "../.."
  alias_name  = var.alias_name
  policy_json = data.aws_iam_policy_document.key.json
  tags        = { Environment = "poc" }
}

output "key_arn" {
  value = module.kms.key_arn
}
