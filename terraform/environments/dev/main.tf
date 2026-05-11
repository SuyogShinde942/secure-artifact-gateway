terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


}

provider "aws" {
  region = var.aws_region
}

locals {
  # Workspace name drives the environment — run `terraform workspace new dev`
  # before applying. Falls back to var.environment if workspace is "default".
  env = terraform.workspace == "default" ? var.environment : terraform.workspace

  tags = {
    Project     = "secure-gateway"
    Environment = local.env
    ManagedBy   = "terraform"
    Workspace   = terraform.workspace
  }
}

module "s3" {
  source = "../../modules/s3"

  bucket_name      = "secure-gateway-artifacts-${local.env}"
  artifacts_prefix = var.artifacts_prefix
  gateway_role_arn = module.iam.role_arn

  tags = local.tags
}

module "iam" {
  source = "../../modules/iam"

  role_name            = "secure-gateway-${local.env}"
  artifacts_bucket_arn = module.s3.bucket_arn
  artifacts_prefix     = var.artifacts_prefix

  tags = local.tags
}
