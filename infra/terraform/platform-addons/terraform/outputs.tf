# Consumed by the addon Helm releases as ServiceAccount annotations. The chart
# never carries a role ARN as a committed value — constitution §4.

output "alb_controller_role_arn" {
  value = module.alb_controller.role_arn
}

output "external_dns_role_arn" {
  value = module.external_dns.role_arn
}

output "ebs_csi_role_arn" {
  value = module.ebs_csi.role_arn
}
