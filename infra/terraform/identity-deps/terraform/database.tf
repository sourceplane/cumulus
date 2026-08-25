# Identity's Postgres. Private, encrypted, and never publicly addressable.

locals {
  private_subnet_ids = compact(split(",", var.privateSubnetIds))
}

resource "aws_db_subnet_group" "identity" {
  name       = "${local.name_prefix}-identity"
  subnet_ids = local.private_subnet_ids
}

resource "aws_security_group" "identity_db" {
  name        = "${local.name_prefix}-identity-db"
  description = "Postgres access for identity-service pods"
  vpc_id      = var.vpcId
  tags        = { Name = "${local.name_prefix}-identity-db" }
}

resource "aws_vpc_security_group_ingress_rule" "identity_db_from_cluster" {
  security_group_id            = aws_security_group.identity_db.id
  referenced_security_group_id = var.nodeSecurityGroupId
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres from cluster nodes"
}

# The master password is generated here and never leaves Terraform except as a
# lease-published output. Nobody types it, so nobody can paste it somewhere.
resource "random_password" "identity_db" {
  length  = 40
  special = false
}

resource "aws_kms_key" "identity_db" {
  description             = "Encryption at rest for ${local.name_prefix}-identity"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_db_instance" "identity" {
  identifier     = "${local.name_prefix}-identity"
  engine         = "postgres"
  engine_version = "16.6"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.identity_db.arn

  db_name  = "identity"
  username = "identity_app"
  password = random_password.identity_db.result

  db_subnet_group_name   = aws_db_subnet_group.identity.name
  vpc_security_group_ids = [aws_security_group.identity_db.id]
  publicly_accessible    = false

  multi_az                = var.environment == "prod"
  backup_retention_period = var.environment == "prod" ? 14 : 7
  backup_window           = "17:00-18:00"
  maintenance_window      = "Sun:18:00-Sun:19:00"

  # A production database that can be destroyed by a `terraform apply` is one
  # typo from an outage with no undo.
  deletion_protection       = var.environment == "prod"
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-identity-final" : null

  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  apply_immediately          = false
}
