output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name, consumed by helm-release for `aws eks update-kubeconfig`."
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "API server endpoint."
}

output "cluster_certificate_authority" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Base64 cluster CA."
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.oidc.arn
  description = "IRSA provider ARN. Every service role's trust policy is written against this."
}

output "oidc_provider_url" {
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
  description = "IRSA issuer without the scheme — the form an IAM trust condition key needs."
}

output "node_security_group_id" {
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description = "Cluster security group. Data-store security groups scope their ingress to this."
}

output "node_role_arn" {
  value       = aws_iam_role.node.arn
  description = "Node instance role."
}
