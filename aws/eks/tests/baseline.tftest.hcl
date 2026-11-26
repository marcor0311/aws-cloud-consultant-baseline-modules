mock_provider "aws" {
  override_during = plan

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_ec2_instance_type" {
    defaults = {
      supported_architectures     = ["x86_64"]
      supported_root_device_types = ["ebs"]
      supported_usages_classes    = ["on-demand"]
    }
  }

  mock_resource "aws_eks_cluster" {
    defaults = {
      arn                   = "arn:aws:eks:us-east-1:123456789012:cluster/test-eks"
      endpoint              = "https://example.eks.amazonaws.com"
      certificate_authority = [{ data = "dGVzdC1jYQ==" }]
    }
  }
}

override_data {
  target = data.aws_subnet.private["subnet-0123456789abcdef0"]
  values = {
    vpc_id                  = "vpc-0123456789abcdef0"
    availability_zone_id    = "use1-az1"
    map_public_ip_on_launch = false
  }
}

override_data {
  target = data.aws_subnet.private["subnet-0123456789abcdef1"]
  values = {
    vpc_id                  = "vpc-0123456789abcdef0"
    availability_zone_id    = "use1-az2"
    map_public_ip_on_launch = false
  }
}

variables {
  name               = "test-eks"
  kubernetes_version = "1.36"
  vpc_id             = "vpc-0123456789abcdef0"
  private_subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]

  iam_role_arns = {
    cluster       = "arn:aws:iam::123456789012:role/eks-control-plane"
    nodes         = "arn:aws:iam::123456789012:role/eks-nodes"
    administrator = "arn:aws:iam::123456789012:role/eks-administrator"
  }

  kms_key_arns = {
    secrets = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    logs    = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789013"
  }

  tags = {
    Project     = "baseline-tests"
    Environment = "test"
    Owner       = "platform"
    CostCenter  = "engineering"
  }
}

run "private_control_plane_and_managed_nodes" {
  command = plan

  assert {
    condition = (
      one(aws_eks_cluster.this.vpc_config).endpoint_private_access &&
      !one(aws_eks_cluster.this.vpc_config).endpoint_public_access &&
      one(aws_eks_cluster.this.access_config).authentication_mode == "API" &&
      !one(aws_eks_cluster.this.access_config).bootstrap_cluster_creator_admin_permissions &&
      aws_eks_access_entry.administrator.principal_arn == var.iam_role_arns.administrator &&
      endswith(aws_eks_access_policy_association.administrator.policy_arn, "/AmazonEKSClusterAdminPolicy") &&
      aws_eks_cluster.this.deletion_protection &&
      one(aws_eks_cluster.this.upgrade_policy).support_type == "STANDARD"
    )
    error_message = "El endpoint, acceso administrativo, soporte y protección del clúster deben seguir los defaults del módulo."
  }

  assert {
    condition = (
      one(one(aws_eks_cluster.this.encryption_config).provider).key_arn == var.kms_key_arns.secrets &&
      aws_eks_cluster.this.enabled_cluster_log_types == toset(["api", "audit", "authenticator", "controllerManager", "scheduler"]) &&
      aws_cloudwatch_log_group.control_plane.kms_key_id == var.kms_key_arns.logs &&
      aws_cloudwatch_log_group.control_plane.retention_in_days == 90
    )
    error_message = "El módulo debe cifrar los datos de Kubernetes y los cinco logs de EKS con las claves configuradas."
  }

  assert {
    condition = (
      one(aws_launch_template.nodes.metadata_options).http_tokens == "required" &&
      one(aws_launch_template.nodes.metadata_options).http_put_response_hop_limit == 1 &&
      one(one(aws_launch_template.nodes.block_device_mappings).ebs).encrypted == "true" &&
      one(one(aws_launch_template.nodes.block_device_mappings).ebs).volume_type == "gp3" &&
      one(aws_eks_node_group.this.scaling_config).desired_size == 2 &&
      aws_eks_node_group.this.capacity_type == "ON_DEMAND" &&
      aws_eks_node_group.this.subnet_ids == var.private_subnet_ids
    )
    error_message = "Los nodos deben usar IMDSv2, discos cifrados y capacidad administrada en las subredes indicadas."
  }
}

run "scaled_node_group" {
  command = plan

  variables {
    node_group = {
      min_size      = 3
      desired_size  = 3
      max_size      = 6
      disk_size_gib = 40
    }
  }

  assert {
    condition = (
      one(aws_eks_node_group.this.scaling_config).min_size == 3 &&
      one(aws_eks_node_group.this.scaling_config).desired_size == 3 &&
      one(aws_eks_node_group.this.scaling_config).max_size == 6
    )
    error_message = "El perfil escalado debe aplicar la capacidad indicada."
  }
}

run "reject_subnets_in_same_zone" {
  command = plan

  override_data {
    target = data.aws_subnet.private["subnet-0123456789abcdef1"]
    values = {
      vpc_id                  = "vpc-0123456789abcdef0"
      availability_zone_id    = "use1-az1"
      map_public_ip_on_launch = false
    }
  }

  expect_failures = [aws_eks_cluster.this]
}

run "reject_subnet_with_public_ip_assignment" {
  command = plan

  override_data {
    target = data.aws_subnet.private["subnet-0123456789abcdef1"]
    values = {
      vpc_id                  = "vpc-0123456789abcdef0"
      availability_zone_id    = "use1-az2"
      map_public_ip_on_launch = true
    }
  }

  expect_failures = [aws_eks_cluster.this]
}

run "reject_inconsistent_capacity" {
  command = plan

  variables {
    node_group = {
      desired_size = 5
      max_size     = 4
    }
  }

  expect_failures = [var.node_group]
}

run "reject_arm_instance_type" {
  command = plan

  override_data {
    target = data.aws_ec2_instance_type.nodes
    values = {
      supported_architectures     = ["arm64"]
      supported_root_device_types = ["ebs"]
      supported_usages_classes    = ["on-demand"]
    }
  }

  expect_failures = [aws_eks_node_group.this]
}
