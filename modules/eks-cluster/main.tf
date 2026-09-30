data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# EKS control plane and managed nodes
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.nodes.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = data.aws_subnets.default.ids
  instance_types  = [var.instance_type]
  ami_type       = "AL2023_ARM_64_STANDARD"

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_size
    max_size     = var.max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policies
  ]
}

# -----------------------------------------------------------------------------
# IAM OIDC provider for this EKS cluster
#
# AWS provider 5.x requires thumbprint_list. AWS's EKS OIDC endpoints use the
# Amazon CA chain; the value below is the standard EKS OIDC fallback thumbprint.
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
  ]
}

locals {
  oidc_issuer_url       = aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_issuer_url_clean = replace(local.oidc_issuer_url, "https://", "")

  repo_explorer_backend_subject = "system:serviceaccount:repo-explorer:repo-explorer-backend-sa"
  gateway_controller_subject     = "system:serviceaccount:kube-system:gateway-controller-sa"
}

# -----------------------------------------------------------------------------
# IRSA trust policies
#
# The Kubernetes service accounts themselves are created by the separate
# kubernetes-bootstrap module. These IAM roles are intentionally kept in the
# AWS/EKS module because they are AWS resources and depend only on the EKS OIDC
# provider, not on the Kubernetes provider.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "repo_explorer_irsa_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.this.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url_clean}:sub"
      values   = [local.repo_explorer_backend_subject]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url_clean}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "gateway_controller_irsa_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.this.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url_clean}:sub"
      values   = [local.gateway_controller_subject]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url_clean}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# -----------------------------------------------------------------------------
# IAM role used by repo-explorer-backend-sa
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ssm_role" {
  name               = "${var.cluster_name}-ssm-backend-role"
  assume_role_policy = data.aws_iam_policy_document.repo_explorer_irsa_trust.json
}

# Custom Parameter Store full-access policy.
# DescribeParameters must use Resource="*"; parameter operations can be scoped
# to the Parameter Store parameter ARN pattern.

resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssm-parameter-store-full-access"
  role = aws_iam_role.ssm_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:AddTagsToResource",
          "ssm:DeleteParameter",
          "ssm:DeleteParameters",
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:GetParameterPolicy",
          "ssm:LabelParameterVersion",
          "ssm:ListTagsForResource",
          "ssm:PutParameter",
          "ssm:PutParameterPolicy",
          "ssm:RemoveTagsFromResource",
          "ssm:UnlabelParameterVersion",
          "ssm:DeleteParameterPolicy"
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM role for the user-managed AWS Load Balancer Controller installation.
# Terraform creates the role and the Kubernetes ServiceAccount, but DOES NOT
# install the controller or attach its controller IAM policy here. The user's
# separate controller-installation script remains responsible for that part.
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lb_role" {
  name               = "${var.cluster_name}-gateway-lb-role"
  assume_role_policy = data.aws_iam_policy_document.gateway_controller_irsa_trust.json
}

# -----------------------------------------------------------------------------
# EKS access entries
# -----------------------------------------------------------------------------

resource "aws_eks_access_entry" "view_only" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.view_only_iam_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "view_only_policy" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.view_only.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.admin_iam_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
