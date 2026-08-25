output "bucket_name" {
  value = aws_s3_bucket.documents.bucket
}

output "cache_endpoint" {
  value       = aws_elasticache_replication_group.cache.primary_endpoint_address
  description = "Primary endpoint. TLS in transit is on, so the client must connect with CACHE_SSL=true."
}

output "cache_port" {
  value = aws_elasticache_replication_group.cache.port
}

output "irsa_role_arn" {
  value       = module.documents_service.role_arn
  description = "Annotated onto the documents-service ServiceAccount by the chart."
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_registry" {
  value       = "${module.ecr.registry_id}.dkr.ecr.${var.awsRegion}.amazonaws.com"
  description = "Registry host consumed by the container-image component as IMAGE_REGISTRY."
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.documents_service.name
}
