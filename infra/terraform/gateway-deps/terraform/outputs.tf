output "irsa_role_arn" {
  value = module.api_gateway.role_arn
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_registry" {
  value = "${module.ecr.registry_id}.dkr.ecr.${var.awsRegion}.amazonaws.com"
}

output "waf_web_acl_arn" {
  value       = aws_wafv2_web_acl.gateway.arn
  description = "Referenced by the gateway Ingress annotation alb.ingress.kubernetes.io/wafv2-acl-arn."
}
