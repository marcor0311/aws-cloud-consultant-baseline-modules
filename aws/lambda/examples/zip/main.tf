provider "aws" {
  region = var.aws_region
}

module "baseline" {
  source = "../.."

  function_name  = var.function_name
  role_arn       = var.role_arn
  log_group_name = var.log_group_name
  filename       = var.filename
  handler        = "handler.main"
  runtime        = "python3.12"
  memory_size    = 256
  tags           = var.tags
}

output "function_arn" {
  value = module.baseline.function_arn
}
