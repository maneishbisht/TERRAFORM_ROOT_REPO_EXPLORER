data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Shared IAM roles used for EKS cluster access
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cluster_admin" {
  name = "cluster-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_admin_read_only" {
  role       = aws_iam_role.cluster_admin.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role" "view_only" {
  name = "cluster-view-only-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

locals {
  admin_role     = aws_iam_role.cluster_admin.arn
  view_only_role = aws_iam_role.view_only.arn
}

# -----------------------------------------------------------------------------
# EKS infrastructure modules
# -----------------------------------------------------------------------------

module "dev_cluster" {
  source = "./modules/eks-cluster"

  cluster_name           = "dev_cluster"
  node_group_name        = "dev-nodes"
  instance_type          = "t4g.small"
  region                 = var.aws_region
  admin_iam_role_arn     = local.admin_role
  view_only_iam_role_arn = local.view_only_role
}

module "test_cluster" {
  source = "./modules/eks-cluster"

  cluster_name           = "test_cluster"
  node_group_name        = "test-nodes"
  instance_type          = "t4g.small"
  region                 = var.aws_region
  admin_iam_role_arn     = local.admin_role
  view_only_iam_role_arn = local.view_only_role
}

#module "prod_cluster" {
#  source = "./modules/eks-cluster"
#
#  cluster_name           = "prod_cluster"
#  node_group_name        = "prod-nodes"
#  instance_type          = "t4g.small"
#  region                 = var.aws_region
#  admin_iam_role_arn     = local.admin_role
#  view_only_iam_role_arn = local.view_only_role
#}

# -----------------------------------------------------------------------------
# Kubernetes/bootstrap modules
#
# No Helm releases are created here. In particular, the AWS Load Balancer
# Controller is intentionally installed by the user's separate script.
# -----------------------------------------------------------------------------

module "dev_bootstrap" {
  source = "./modules/kubernetes-bootstrap"

  providers = {
    kubernetes = kubernetes.dev
  }

  repo_explorer_backend_role_arn = module.dev_cluster.repo_explorer_backend_role_arn
  gateway_controller_role_arn    = module.dev_cluster.gateway_controller_role_arn

  depends_on = [module.dev_cluster]
}

module "test_bootstrap" {
  source = "./modules/kubernetes-bootstrap"

  providers = {
    kubernetes = kubernetes.test
  }

  repo_explorer_backend_role_arn = module.test_cluster.repo_explorer_backend_role_arn
  gateway_controller_role_arn    = module.test_cluster.gateway_controller_role_arn

  depends_on = [module.test_cluster]
}

#module "prod_bootstrap" {
#  source = "./modules/kubernetes-bootstrap"
#
#  providers = {
#    kubernetes = kubernetes.prod
#  }
#
#  repo_explorer_backend_role_arn = module.prod_cluster.repo_explorer_backend_role_arn
#  gateway_controller_role_arn    = module.prod_cluster.gateway_controller_role_arn
#
#  depends_on = [module.prod_cluster]
#}
