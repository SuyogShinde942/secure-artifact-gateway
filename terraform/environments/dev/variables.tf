variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "artifacts_prefix" {
  description = "S3 key prefix that validated artifacts are written under"
  type        = string
}
