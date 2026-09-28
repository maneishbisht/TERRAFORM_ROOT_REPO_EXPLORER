# Terraform EKS + Kubernetes Bootstrap

This configuration creates three EKS clusters (`dev_cluster`, `test_cluster`, `prod_cluster`) in `ap-south-1`.

## Structure

- `modules/eks-cluster`: AWS/EKS infrastructure only
- `modules/kubernetes-bootstrap`: Kubernetes namespace and ServiceAccounts only
- Root `provider.tf`: EKS data sources and aliased Kubernetes providers using `aws eks get-token`

## Applied decisions

- IAM OIDC provider is created for each cluster.
- EKS authentication mode is `API_AND_CONFIG_MAP`.
- `AmazonEKSViewPolicy` and `AmazonEKSClusterAdminPolicy` use EKS cluster-access-policy ARNs.
- `repo-explorer` namespace is created before `repo-explorer-backend-sa`.
- IRSA subject uses `system:serviceaccount:repo-explorer:repo-explorer-backend-sa`.
- Custom Parameter Store full-access policy is attached to the backend IRSA role.
- Cross-cluster Argo CD IAM role/trust is removed.
- The AWS Load Balancer Controller is NOT installed by Terraform.

## AWS Load Balancer Controller

Terraform creates:

- IAM role: `<cluster>-gateway-lb-role`
- ServiceAccount: `kube-system/gateway-controller-sa`

The separate controller-installation script must install the controller and provide/attach the controller's required IAM permissions to that role.

## Apply

1. Ensure the AWS CLI is installed and your local AWS credential chain can assume/use the IAM identity that has access to the EKS clusters.
2. Run `terraform init`.
3. Run `terraform plan`.
4. Run `terraform apply`.
5. After cluster/bootstrap creation, run your existing AWS Load Balancer Controller installation script.

## Existing IAM OIDC providers

If an IAM OIDC provider for a cluster already exists outside this Terraform state, import it rather than attempting to create a duplicate resource.

## SecureString note

If the application reads `SecureString` parameters encrypted with a customer-managed KMS key, the IRSA role also needs the appropriate `kms:Decrypt` permission on that KMS key. The Parameter Store policy itself does not grant KMS access.
