module "network" {
  source             = "../.."
  name               = var.name
  availability_zones = var.availability_zones
  tags               = var.tags
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}
