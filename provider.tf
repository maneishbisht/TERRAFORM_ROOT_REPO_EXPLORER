provider "aws" {
  region = var.aws_region
}

# These data sources are intentionally evaluated only after the corresponding
# EKS clusters have been created. This lets the Kubernetes provider use the
# real cluster endpoint and CA while keeping Kubernetes resources outside the
# EKS infrastructure module.
locals {
  clusters = {
    dev = {
      cluster_name = module.dev_cluster.cluster_name
    }
    test = {
      cluster_name = module.test_cluster.cluster_name
    }
    prod = {
      cluster_name = module.prod_cluster.cluster_name
    }
  }
}

data "aws_eks_cluster" "clusters" {
  for_each = local.clusters

  name = each.value.cluster_name

  depends_on = [
    module.dev_cluster,
    module.test_cluster,
    module.prod_cluster
  ]
}

provider "kubernetes" {
  alias = "dev"

  host                   = data.aws_eks_cluster.clusters["dev"].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["dev"].certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      data.aws_eks_cluster.clusters["dev"].name
    ]
  }
}

provider "kubernetes" {
  alias = "test"

  host                   = data.aws_eks_cluster.clusters["test"].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["test"].certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"

    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      data.aws_eks_cluster.clusters["test"].name
    ]
  }
}

provider "kubernetes" {
  alias = "prod"

  host                   = data.aws_eks_cluster.clusters["prod"].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.clusters["prod"].certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"

    args = [
      "eks",
      "get-token",
      "--region",
      var.aws_region,
      "--cluster-name",
      data.aws_eks_cluster.clusters["prod"].name
    ]
  }
}
