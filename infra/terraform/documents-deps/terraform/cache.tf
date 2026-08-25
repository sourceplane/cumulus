# The read cache. Optional by design: the service degrades to S3 when this is
# unreachable, and /health/ready reports degraded rather than down.

locals {
  private_subnet_ids = compact(split(",", var.privateSubnetIds))
}

resource "aws_elasticache_subnet_group" "cache" {
  name       = "${local.name_prefix}-documents-cache"
  subnet_ids = local.private_subnet_ids
}

resource "aws_security_group" "cache" {
  name        = "${local.name_prefix}-documents-cache"
  description = "Redis access for documents-service pods"
  vpc_id      = var.vpcId

  tags = { Name = "${local.name_prefix}-documents-cache" }
}

# Ingress is scoped to the cluster security group, not to the VPC CIDR. A
# CIDR-scoped rule admits anything that ever gets an address in the VPC —
# including a future subnet nobody thought about when this was written.
resource "aws_vpc_security_group_ingress_rule" "cache_from_cluster" {
  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = var.nodeSecurityGroupId
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Redis from cluster nodes"
}

resource "aws_elasticache_replication_group" "cache" {
  replication_group_id = "${local.name_prefix}-documents"
  description          = "Cache-aside read cache for documents-service"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t4g.micro"
  port           = 6379

  # Two nodes across two AZs. A single-node cache whose loss is survivable is
  # still a cache whose loss causes a latency cliff at exactly the wrong moment.
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.cache.name
  security_group_ids = [aws_security_group.cache.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # The cache holds document bodies. It is not the system of record, so a
  # snapshot restore is never the recovery path — retaining backups of it would
  # be storing customer content in a second place for no benefit.
  snapshot_retention_limit = 0

  apply_immediately = false
}
