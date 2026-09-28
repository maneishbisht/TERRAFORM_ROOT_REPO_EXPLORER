output "cluster_endpoints" {
  value = {
    dev  = module.dev_cluster.cluster_endpoint
    test = module.test_cluster.cluster_endpoint
    prod = module.prod_cluster.cluster_endpoint
  }
}

output "cluster_names" {
  value = {
    dev  = module.dev_cluster.cluster_name
    test = module.test_cluster.cluster_name
    prod = module.prod_cluster.cluster_name
  }
}

output "oidc_issuer_urls" {
  value = {
    dev  = module.dev_cluster.oidc_issuer_url
    test = module.test_cluster.oidc_issuer_url
    prod = module.prod_cluster.oidc_issuer_url
  }
}

output "oidc_issuer_url_clean" {
  value = {
    dev  = module.dev_cluster.oidc_issuer_url_clean
    test = module.test_cluster.oidc_issuer_url_clean
    prod = module.prod_cluster.oidc_issuer_url_clean
  }
}

output "oidc_provider_arns" {
  value = {
    dev  = module.dev_cluster.oidc_provider_arn
    test = module.test_cluster.oidc_provider_arn
    prod = module.prod_cluster.oidc_provider_arn
  }
}

output "repo_explorer_backend_role_arns" {
  value = {
    dev  = module.dev_cluster.repo_explorer_backend_role_arn
    test = module.test_cluster.repo_explorer_backend_role_arn
    prod = module.prod_cluster.repo_explorer_backend_role_arn
  }
}

output "gateway_controller_role_arns" {
  value = {
    dev  = module.dev_cluster.gateway_controller_role_arn
    test = module.test_cluster.gateway_controller_role_arn
    prod = module.prod_cluster.gateway_controller_role_arn
  }
}
