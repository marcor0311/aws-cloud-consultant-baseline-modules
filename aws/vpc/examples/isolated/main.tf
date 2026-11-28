module "network" {
  source             = "../.."
  name               = var.name
  availability_zones = var.availability_zones
  internet_egress    = false
  tags               = var.tags
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

