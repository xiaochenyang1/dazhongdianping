variable "aws_region" {
  description = "AWS region for the isolated EU test stack."
  type        = string
  default     = "eu-west-3"

  validation {
    condition     = var.aws_region == "eu-west-3"
    error_message = "The AWS EU test baseline is fixed to eu-west-3 (Paris)."
  }
}

variable "environment" {
  description = "Deployment environment represented by this root module."
  type        = string
  default     = "test"

  validation {
    condition     = var.environment == "test"
    error_message = "This root module may provision only the test environment."
  }
}

variable "project_name" {
  description = "Short lowercase name used in AWS resource names."
  type        = string
  default     = "dzdp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,11}$", var.project_name))
    error_message = "project_name must be 2-12 lowercase alphanumeric or hyphen characters and start with a letter."
  }
}

variable "additional_tags" {
  description = "Extra non-sensitive tags to merge into every supported resource."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the EU test VPC."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && length(distinct(var.public_subnet_cidrs)) == 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain two distinct IPv4 CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Two private data subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2 && length(distinct(var.private_subnet_cidrs)) == 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain two distinct IPv4 CIDRs."
  }
}

variable "availability_zones" {
  description = "Optional explicit pair of eu-west-3 availability zones; leave empty to select the first two available zones."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || (length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2 && alltrue([for zone in var.availability_zones : startswith(zone, "eu-west-3")]))
    error_message = "availability_zones must be empty or contain two distinct eu-west-3 zones."
  }
}

variable "ssh_public_key" {
  description = "Reviewed SSH public key installed for both ubuntu provisioning and deploy release access."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(ed25519|rsa)|ecdsa-sha2-nistp(256|384|521)) [A-Za-z0-9+/=]+(?: .*)?$", trimspace(var.ssh_public_key)))
    error_message = "ssh_public_key must be a single OpenSSH public key, never a private key."
  }
}

variable "ssh_ingress_cidrs" {
  description = "Approved operator IPv4 CIDRs allowed to reach SSH; 0.0.0.0/0 is rejected."
  type        = list(string)

  validation {
    condition     = length(var.ssh_ingress_cidrs) > 0 && length(distinct(var.ssh_ingress_cidrs)) == length(var.ssh_ingress_cidrs) && alltrue([for cidr in var.ssh_ingress_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "ssh_ingress_cidrs must contain distinct IPv4 CIDRs and must not include 0.0.0.0/0."
  }
}

variable "web_ingress_cidrs" {
  description = "IPv4 CIDRs allowed to reach nginx on ports 80 and 443."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.web_ingress_cidrs) > 0 && alltrue([for cidr in var.web_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "web_ingress_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "target_instance_type" {
  description = "EC2 instance type for the Ubuntu target host."
  type        = string
  default     = "t3.small"
}

variable "target_root_volume_gib" {
  description = "Encrypted gp3 root volume size for the target host."
  type        = number
  default     = 30

  validation {
    condition     = var.target_root_volume_gib >= 20 && var.target_root_volume_gib <= 1024
    error_message = "target_root_volume_gib must be between 20 and 1024 GiB."
  }
}

variable "database_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "dazhongdianping_eu_test"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,63}$", var.database_name))
    error_message = "database_name must be a valid MySQL identifier without punctuation other than underscore."
  }
}

variable "database_master_username" {
  description = "RDS bootstrap administrator name; its generated password is managed by RDS in Secrets Manager."
  type        = string
  default     = "dzdp_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,15}$", var.database_master_username))
    error_message = "database_master_username must be a valid RDS MySQL username of at most 16 characters."
  }
}

variable "database_instance_class" {
  description = "RDS instance class for the test database."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_allocated_storage_gib" {
  description = "Initial gp3 storage allocated to RDS."
  type        = number
  default     = 20

  validation {
    condition     = var.database_allocated_storage_gib >= 20 && var.database_allocated_storage_gib <= 65536
    error_message = "database_allocated_storage_gib must be between 20 and 65536 GiB."
  }
}

variable "database_max_allocated_storage_gib" {
  description = "RDS storage autoscaling ceiling."
  type        = number
  default     = 100

  validation {
    condition     = var.database_max_allocated_storage_gib >= var.database_allocated_storage_gib
    error_message = "database_max_allocated_storage_gib must be at least database_allocated_storage_gib."
  }
}

variable "database_deletion_protection" {
  description = "Protect the test database from deletion. Enable after lifecycle and cleanup procedures are approved."
  type        = bool
  default     = false
}
variable "database_skip_final_snapshot" {
  description = "Skip the final RDS snapshot on destroy. The disposable test default must be reviewed before apply."
  type        = bool
  default     = true
}

variable "redis_node_type" {
  description = "ElastiCache node type for the single-node test replication group."
  type        = string
  default     = "cache.t4g.micro"
}

variable "opensearch_instance_type" {
  description = "OpenSearch data-node type for the single-node test domain."
  type        = string
  default     = "t3.small.search"
}

variable "opensearch_volume_gib" {
  description = "Encrypted gp3 storage allocated to OpenSearch."
  type        = number
  default     = 20

  validation {
    condition     = var.opensearch_volume_gib >= 10 && var.opensearch_volume_gib <= 100
    error_message = "opensearch_volume_gib must be between 10 and 100 GiB for this test baseline."
  }
}

variable "assets_force_destroy" {
  description = "Allow Terraform to delete non-empty asset buckets. Keep false unless test-data cleanup is explicitly approved."
  type        = bool
  default     = false
}
