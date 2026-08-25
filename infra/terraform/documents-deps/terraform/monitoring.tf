resource "aws_cloudwatch_log_group" "documents_service" {
  name              = "/cumulus/${var.environment}/documents-service"
  retention_in_days = 30
}

# Alarms on the cache, because a silently-cold cache looks exactly like a slow
# origin until someone graphs it.
resource "aws_cloudwatch_metric_alarm" "cache_evictions" {
  alarm_name          = "${local.name_prefix}-documents-cache-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Cache is evicting under memory pressure; hit rate will fall and S3 read volume will rise."
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.cache.replication_group_id
  }
}

resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  alarm_name          = "${local.name_prefix}-documents-cache-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Redis engine CPU sustained above 75%."
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.cache.replication_group_id
  }
}
