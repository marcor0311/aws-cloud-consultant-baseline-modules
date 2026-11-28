module "service" {
  source                   = "../.."
  name                     = var.name
  image                    = var.image
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  source_security_group_id = var.alb_security_group_id
  target_group_arn         = var.target_group_arn
  security_group_ids       = var.security_group_ids
  environment              = { LOG_LEVEL = "info" }
  tags                     = var.tags
}

output "cluster_arn" {
  value = module.service.cluster_arn
}

output "service_name" {
  value = module.service.service_name
}

output "task_definition_arn" {
  value = module.service.task_definition_arn
}
