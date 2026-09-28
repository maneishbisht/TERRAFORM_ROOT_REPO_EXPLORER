output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "oidc_issuer_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_issuer_url_clean" {
  value = local.oidc_issuer_url_clean
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "repo_explorer_backend_role_arn" {
  value = aws_iam_role.ssm_role.arn
}

output "gateway_controller_role_arn" {
  value = aws_iam_role.lb_role.arn
}
