resource "aws_security_group" "target" {
  name_prefix            = "${local.name_prefix}-target-"
  description            = "Public nginx and restricted SSH for the EU test target"
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.name_prefix}-target"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "target_ssh" {
  for_each = toset(var.ssh_ingress_cidrs)

  security_group_id = aws_security_group.target.id
  description       = "Reviewed operator SSH source ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "target_http" {
  for_each = toset(var.web_ingress_cidrs)

  security_group_id = aws_security_group.target.id
  description       = "HTTP redirect and certificate bootstrap from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "target_https" {
  for_each = toset(var.web_ingress_cidrs)

  security_group_id = aws_security_group.target.id
  description       = "Public HTTPS from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "target_ipv4" {
  security_group_id = aws_security_group.target.id
  description       = "Outbound package, supplier, AWS API, and managed-service access"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "mysql" {
  name_prefix            = "${local.name_prefix}-mysql-"
  description            = "MySQL reachable only from the target host"
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.name_prefix}-mysql"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_from_target" {
  security_group_id            = aws_security_group.mysql.id
  description                  = "MySQL TLS from the application target"
  referenced_security_group_id = aws_security_group.target.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "redis" {
  name_prefix            = "${local.name_prefix}-redis-"
  description            = "Redis TLS reachable only from the target host"
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.name_prefix}-redis"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_target" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis TLS from the application target"
  referenced_security_group_id = aws_security_group.target.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "opensearch" {
  name_prefix            = "${local.name_prefix}-search-"
  description            = "OpenSearch HTTPS reachable only from the target host"
  vpc_id                 = aws_vpc.this.id
  revoke_rules_on_delete = true

  tags = {
    Name = "${local.name_prefix}-search"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "opensearch_from_target" {
  security_group_id            = aws_security_group.opensearch.id
  description                  = "OpenSearch HTTPS from the application target"
  referenced_security_group_id = aws_security_group.target.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
