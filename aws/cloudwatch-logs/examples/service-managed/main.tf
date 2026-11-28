provider "aws" {
  region = var.aws_region
}

module "baseline" {
  source = "../.."

  name = var.name
  tags = var.tags
}

output "log_group_arn" {
  value = module.baseline.log_group_arn
}
