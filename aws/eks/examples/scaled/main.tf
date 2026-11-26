module "baseline" {
  source = "../.."

  name               = var.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  iam_role_arns      = var.iam_role_arns
  kms_key_arns       = var.kms_key_arns
  tags               = var.tags

  node_group = {
    min_size      = 3
    desired_size  = 3
    max_size      = 6
    disk_size_gib = 40
  }

}

output "cluster_name" {
  description = "Nombre del clúster creado por el ejemplo."
  value       = module.baseline.cluster_name
}
