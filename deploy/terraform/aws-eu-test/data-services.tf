resource "aws_db_subnet_group" "mysql" {
  name       = "${local.name_prefix}-mysql"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.name_prefix}-mysql"
  }
}

resource "aws_db_parameter_group" "mysql" {
  name   = "${local.name_prefix}-mysql8"
  family = "mysql8.0"

  parameter {
    name         = "require_secure_transport"
    value        = "1"
    apply_method = "immediate"
  }

  tags = {
    Name = "${local.name_prefix}-mysql8"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${local.name_prefix}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.database_instance_class
  port           = 3306

  db_name                     = var.database_name
  username                    = var.database_master_username
  manage_master_user_password = true

  allocated_storage     = var.database_allocated_storage_gib
  max_allocated_storage = var.database_max_allocated_storage_gib
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  parameter_group_name   = aws_db_parameter_group.mysql.name
  vpc_security_group_ids = [aws_security_group.mysql.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 7
  backup_window           = "01:00-02:00"
  maintenance_window      = "sun:03:00-sun:04:00"

  auto_minor_version_upgrade          = true
  allow_major_version_upgrade         = false
  apply_immediately                   = false
  ca_cert_identifier                  = "rds-ca-rsa2048-g1"
  copy_tags_to_snapshot               = true
  deletion_protection                 = var.database_deletion_protection
  delete_automated_backups            = true
  iam_database_authentication_enabled = true
  performance_insights_enabled        = false
  skip_final_snapshot                 = var.database_skip_final_snapshot
  final_snapshot_identifier           = var.database_skip_final_snapshot ? null : "${local.name_prefix}-mysql-final"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  tags = {
    Name = "${local.name_prefix}-mysql"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name_prefix}-redis"
  subnet_ids = aws_subnet.private[*].id
}

resource "random_password" "redis" {
  length  = 48
  special = false

  min_lower   = 12
  min_numeric = 12
  min_upper   = 12
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Dazhongdianping EU test encrypted Redis"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
  auth_token                 = random_password.redis.result

  auto_minor_version_upgrade = true
  apply_immediately          = false
  maintenance_window         = "sun:04:00-sun:05:00"
  snapshot_retention_limit   = 1
  snapshot_window            = "02:00-03:00"

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_secretsmanager_secret" "redis" {
  name                    = "${local.name_prefix}/redis"
  description             = "Generated Redis TLS credentials and endpoint for EU test"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    password = random_password.redis.result
    port     = aws_elasticache_replication_group.redis.port
    tls      = true
    username = "default"
  })
}

resource "random_password" "opensearch" {
  length  = 32
  special = false

  min_lower   = 8
  min_numeric = 8
  min_upper   = 8
}

resource "aws_iam_service_linked_role" "opensearch" {
  aws_service_name = "opensearchservice.amazonaws.com"
  description      = "Allows Amazon OpenSearch Service to manage VPC resources"
}

resource "aws_opensearch_domain" "this" {
  domain_name    = local.name_prefix
  engine_version = "OpenSearch_2.17"

  cluster_config {
    dedicated_master_enabled = false
    instance_count           = 1
    instance_type            = var.opensearch_instance_type
    zone_awareness_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_volume_gib
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    anonymous_auth_enabled         = false

    master_user_options {
      master_user_name     = "dzdp_search_admin"
      master_user_password = random_password.opensearch.result
    }
  }

  vpc_options {
    security_group_ids = [aws_security_group.opensearch.id]
    subnet_ids         = [aws_subnet.private[0].id]
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:ESHttp*"
        Resource = "arn:${data.aws_partition.current.partition}:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.name_prefix}/*"
      },
    ]
  })

  software_update_options {
    auto_software_update_enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-search"
  }

  depends_on = [aws_iam_service_linked_role.opensearch]
}

resource "aws_secretsmanager_secret" "opensearch" {
  name                    = "${local.name_prefix}/opensearch"
  description             = "Generated OpenSearch internal-user credentials and endpoint for EU test"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "opensearch" {
  secret_id = aws_secretsmanager_secret.opensearch.id
  secret_string = jsonencode({
    endpoint = "https://${aws_opensearch_domain.this.endpoint}"
    password = random_password.opensearch.result
    username = "dzdp_search_admin"
  })
}
