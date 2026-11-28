provider "aws" {
  region = var.aws_region
}

module "baseline" {
  source = "../.."

  name              = var.name
  retention_in_days = 90
  kms_key_arn       = var.kms_key_arn
  tags              = var.tags
}

output "log_group_arn" {
  value = module.baseline.log_group_arn
}
