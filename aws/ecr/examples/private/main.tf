module "images" {
  source       = "../.."
  name         = var.name
  force_delete = var.force_delete
  tags         = var.tags
}

output "repository_url" {
  value = module.images.repository_url
}
