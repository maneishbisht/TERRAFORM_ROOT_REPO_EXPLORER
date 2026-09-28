output "repo_explorer_namespace" {
  value = kubernetes_namespace.repo_explorer.metadata[0].name
}

output "repo_explorer_backend_service_account" {
  value = kubernetes_service_account.repo_explorer_backend.metadata[0].name
}

output "gateway_controller_service_account" {
  value = kubernetes_service_account.gateway_controller.metadata[0].name
}
