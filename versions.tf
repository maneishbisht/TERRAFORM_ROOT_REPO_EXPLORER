terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
    backend "s3" {
    bucket       = "repoexplorerstatebucket"
    key          = "rootrepoexplorer.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}
