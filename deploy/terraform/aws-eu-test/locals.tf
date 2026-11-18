data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project_name}-eu-${var.environment}"
  selected_availability_zones = length(var.availability_zones) == 2 ? var.availability_zones : slice(
    data.aws_availability_zones.available.names,
    0,
    2,
  )

  common_tags = merge(
    var.additional_tags,
    {
      Application   = "dazhongdianping"
      DataResidency = "EU"
      Environment   = var.environment
      ManagedBy     = "Terraform"
      Stack         = "aws-eu-test"
    },
  )
}
