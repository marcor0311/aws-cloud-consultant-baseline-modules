module "load_balancer" {
  source              = "../.."
  name                = var.name
  vpc_id              = var.vpc_id
  subnet_ids          = var.public_subnet_ids
  certificate_arn     = var.certificate_arn
  security_group_ids  = var.security_group_ids
  deletion_protection = var.deletion_protection
  tags                = var.tags
}

output "dns_name" {
  value = module.load_balancer.dns_name
}

output "target_group_arn" {
  value = module.load_balancer.target_group_arn
}

output "security_group_id" {
  value = module.load_balancer.security_group_id
}
