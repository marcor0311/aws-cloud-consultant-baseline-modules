data "aws_partition" "current" {}

data "aws_subnet" "private" {
  for_each = var.private_subnet_ids
  id       = each.value
}

data "aws_ec2_instance_type" "nodes" {
  instance_type = var.node_group.instance_type
}

resource "aws_cloudwatch_log_group" "control_plane" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arns.logs
  tags              = var.tags
}

resource "aws_eks_cluster" "this" {
  name                      = var.name
  role_arn                  = var.iam_role_arns.cluster
  version                   = var.kubernetes_version
  deletion_protection       = var.deletion_protection_enabled
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  tags                      = var.tags

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arns.secrets
    }
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for subnet in data.aws_subnet.private :
        subnet.vpc_id == var.vpc_id && !subnet.map_public_ip_on_launch
      ])
      error_message = "Todas las subredes deben pertenecer a la VPC indicada y tener deshabilitada la asignación automática de IP pública."
    }

    precondition {
      condition     = length(toset([for subnet in data.aws_subnet.private : subnet.availability_zone_id])) >= 2
      error_message = "EKS requiere subredes en al menos dos zonas de disponibilidad distintas."
    }
  }

  depends_on = [aws_cloudwatch_log_group.control_plane]
}

resource "aws_eks_access_entry" "administrator" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.iam_role_arns.administrator
  type          = "STANDARD"
  tags          = var.tags
}

resource "aws_eks_access_policy_association" "administrator" {
  cluster_name  = aws_eks_access_entry.administrator.cluster_name
  principal_arn = aws_eks_access_entry.administrator.principal_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_launch_template" "nodes" {
  name_prefix = "${var.name}-nodes-"
  tags        = var.tags

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.node_group.disk_size_gib
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-managed"
  node_role_arn   = var.iam_role_arns.nodes
  subnet_ids      = var.private_subnet_ids
  version         = aws_eks_cluster.this.version
  ami_type        = "AL2023_x86_64_STANDARD"
  capacity_type   = "ON_DEMAND"
  instance_types  = [var.node_group.instance_type]
  tags            = var.tags

  launch_template {
    id      = aws_launch_template.nodes.id
    version = tostring(aws_launch_template.nodes.latest_version)
  }

  scaling_config {
    min_size     = var.node_group.min_size
    desired_size = var.node_group.desired_size
    max_size     = var.node_group.max_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    precondition {
      condition = (
        contains(data.aws_ec2_instance_type.nodes.supported_architectures, "x86_64") &&
        contains(data.aws_ec2_instance_type.nodes.supported_root_device_types, "ebs") &&
        contains(data.aws_ec2_instance_type.nodes.supported_usages_classes, "on-demand")
      )
      error_message = "El tipo de instancia debe admitir x86-64, arranque por EBS y capacidad On-Demand."
    }
  }
}
