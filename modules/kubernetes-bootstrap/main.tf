# -----------------------------------------------------------------------------
# repo-explorer namespace
# -----------------------------------------------------------------------------

resource "kubernetes_namespace" "repo_explorer" {
  metadata {
    name = "repo-explorer"
  }
}

# -----------------------------------------------------------------------------
# ServiceAccount used by the repo-explorer backend for IRSA
# -----------------------------------------------------------------------------

resource "kubernetes_service_account" "repo_explorer_backend" {
  metadata {
    name      = "repo-explorer-backend-sa"
    namespace = kubernetes_namespace.repo_explorer.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" =   var.repo_explorer_backend_role_arn
    }
  }
  depends_on = [
    kubernetes_namespace.repo_explorer
  ]
}

# -----------------------------------------------------------------------------
# ServiceAccount consumed by the user's external AWS Load Balancer Controller
# installation script.
# -----------------------------------------------------------------------------

resource "kubernetes_service_account" "gateway_controller" {
  metadata {
    name      = "gateway-controller-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = var.gateway_controller_role_arn
    }
  }
}
