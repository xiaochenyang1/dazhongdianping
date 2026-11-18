output "target_host" {
  description = "Non-sensitive target-host connection metadata. DNS and trusted TLS remain separate prerequisites."
  value = {
    instance_id       = aws_instance.target.id
    public_ip         = aws_eip.target.public_ip
    provisioning_user = "ubuntu"
    release_user      = "deploy"
    security_group_id = aws_security_group.target.id
  }
}

output "mysql" {
  description = "Non-sensitive RDS connection metadata and the ARN of the RDS-managed bootstrap secret."
  value = {
    address           = aws_db_instance.mysql.address
    database          = aws_db_instance.mysql.db_name
    master_secret_arn = aws_db_instance.mysql.master_user_secret[0].secret_arn
    port              = aws_db_instance.mysql.port
    username          = aws_db_instance.mysql.username
  }
}

output "redis" {
  description = "Non-sensitive Redis endpoint metadata and credential secret ARN."
  value = {
    host       = aws_elasticache_replication_group.redis.primary_endpoint_address
    port       = aws_elasticache_replication_group.redis.port
    secret_arn = aws_secretsmanager_secret.redis.arn
    tls        = true
  }
}

output "opensearch" {
  description = "Non-sensitive OpenSearch endpoint metadata and internal-user credential secret ARN."
  value = {
    base_url   = "https://${aws_opensearch_domain.this.endpoint}"
    secret_arn = aws_secretsmanager_secret.opensearch.arn
  }
}

output "asset_storage" {
  description = "Non-sensitive S3 and CloudFront values for the application runtime."
  value = {
    bucket_name         = aws_s3_bucket.assets.id
    cloudfront_base_url = "https://${aws_cloudfront_distribution.assets.domain_name}"
    region              = var.aws_region
  }
}

output "runtime_environment_hints" {
  description = "Non-secret values to transfer into the private eu-test.env after review. Passwords must be read from Secrets Manager outside Terraform output."
  value = {
    APP_DB_HOST                       = aws_db_instance.mysql.address
    APP_DB_ALLOW_PUBLIC_KEY_RETRIEVAL = "false"
    APP_DB_NAME                       = aws_db_instance.mysql.db_name
    APP_DB_PORT                       = tostring(aws_db_instance.mysql.port)
    APP_DB_SSL_MODE                   = "REQUIRED"
    APP_FILE_STORAGE_PROVIDER         = "s3"
    APP_REDIS_DATABASE                = "0"
    APP_REDIS_HEALTH_ENABLED          = "true"
    APP_REDIS_HOST                    = aws_elasticache_replication_group.redis.primary_endpoint_address
    APP_REDIS_PORT                    = tostring(aws_elasticache_replication_group.redis.port)
    APP_REDIS_SSL_ENABLED             = "true"
    APP_SEARCH_BASE_URL               = "https://${aws_opensearch_domain.this.endpoint}"
    APP_SEARCH_FALLBACK_ON_ERROR      = "false"
    APP_SEARCH_INDEX_NAME             = "dzdp_shop_eu_test_v1"
    APP_SEARCH_PROVIDER               = "elasticsearch"
    APP_SEARCH_USERNAME               = "dzdp_search_admin"
    APP_S3_BUCKET                     = aws_s3_bucket.assets.id
    APP_S3_CREDENTIALS_PROVIDER       = "default_chain"
    APP_S3_ENDPOINT                   = "https://s3.${var.aws_region}.amazonaws.com"
    APP_S3_PATH_STYLE_ACCESS_ENABLED  = "false"
    APP_S3_PUBLIC_BASE_URL            = "https://${aws_cloudfront_distribution.assets.domain_name}"
    APP_S3_REGION                     = var.aws_region
    APP_STATE_STORE_PROVIDER          = "redis"
    APP_TRUSTED_PROXY_REGEX           = "^127[.]0[.]0[.]1$"
  }
}

output "runtime_secret_arns" {
  description = "Secret identifiers only; Terraform never emits their values."
  value = {
    mysql_bootstrap = aws_db_instance.mysql.master_user_secret[0].secret_arn
    opensearch      = aws_secretsmanager_secret.opensearch.arn
    redis           = aws_secretsmanager_secret.redis.arn
  }
}
