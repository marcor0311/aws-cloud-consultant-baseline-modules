module "database" {
  source                    = "../.."
  identifier                = var.identifier
  vpc_id                    = var.vpc_id
  subnet_ids                = var.private_subnet_ids
  client_security_group_ids = var.client_security_group_ids
  security_group_ids        = var.security_group_ids
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  multi_az                  = true
  instance_class            = "db.m7g.large"
  tags                      = var.tags
}

output "endpoint" {
  value = module.database.endpoint
}

output "master_user_secret_arn" {
  value = module.database.master_user_secret_arn
}
