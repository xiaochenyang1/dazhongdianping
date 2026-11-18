data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "target" {
  key_name   = "${local.name_prefix}-target"
  public_key = trimspace(var.ssh_public_key)

  tags = {
    Name = "${local.name_prefix}-target"
  }
}

resource "aws_iam_role" "target" {
  name = "${local.name_prefix}-target"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "target" {
  name = "${local.name_prefix}-runtime"
  role = aws_iam_role.target.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListAssetBucket"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
        ]
        Resource = aws_s3_bucket.assets.arn
      },
      {
        Sid    = "ManageAssetObjects"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      },
      {
        Sid    = "ReadRuntimeSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          aws_secretsmanager_secret.redis.arn,
          aws_secretsmanager_secret.opensearch.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "target" {
  name = "${local.name_prefix}-target"
  role = aws_iam_role.target.name
}

resource "aws_instance" "target" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = var.target_instance_type
  availability_zone           = local.selected_availability_zones[0]
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.target.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.target.key_name
  iam_instance_profile        = aws_iam_instance_profile.target.name

  user_data = templatefile("${path.module}/cloud-init.tftpl", {
    deploy_ssh_public_key = trimspace(var.ssh_public_key)
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.target_root_volume_gib
    volume_type           = "gp3"
  }

  tags = {
    Name = "${local.name_prefix}-target"
    Role = "target-host"
  }

  depends_on = [aws_iam_role_policy.target]
}

resource "aws_eip" "target" {
  domain   = "vpc"
  instance = aws_instance.target.id

  tags = {
    Name = "${local.name_prefix}-target"
  }

  depends_on = [aws_internet_gateway.this]
}
