output "database_url" {
  value       = "postgresql://${aws_db_instance.identity.username}:${random_password.identity_db.result}@${aws_db_instance.identity.endpoint}/${aws_db_instance.identity.db_name}?sslmode=require"
  sensitive   = true
  description = "Full DSN, lease-published to the environment rung and resolved into the service and the migration lane as secretEnv."
}

output "database_host" {
  value = aws_db_instance.identity.address
}

output "database_name" {
  value = aws_db_instance.identity.db_name
}

output "irsa_role_arn" {
  value = module.identity_service.role_arn
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_registry" {
  value = "${module.ecr.registry_id}.dkr.ecr.${var.awsRegion}.amazonaws.com"
}
