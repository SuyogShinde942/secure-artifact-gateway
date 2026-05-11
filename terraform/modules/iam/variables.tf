variable "role_name" {
  description = "Name of the IAM role attached to the Gateway instance"
  type        = string

  validation {
    condition     = length(var.role_name) <= 64 && can(regex("^[\\w+=,.@-]+$", var.role_name))
    error_message = "role_name must be 64 characters or fewer and contain only alphanumeric characters or +=,.@- symbols."
  }
}

variable "trusted_service" {
  description = "AWS service principal allowed to assume this role"
  type        = string
  default     = "ec2.amazonaws.com"

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.amazonaws\\.com$", var.trusted_service))
    error_message = "trusted_service must be a valid AWS service principal ending in .amazonaws.com."
  }
}

variable "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket that receives validated artifacts"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:s3:::", var.artifacts_bucket_arn))
    error_message = "artifacts_bucket_arn must be a valid S3 ARN starting with arn:aws:s3:::."
  }
}

variable "artifacts_prefix" {
  description = "S3 key prefix the role is allowed to write under"
  type        = string
  default     = "validated/"

  validation {
    condition     = can(regex("^[^/].*/$", var.artifacts_prefix))
    error_message = "artifacts_prefix must not start with / and must end with /."
  }
}

variable "tags" {
  description = "Tags applied to all IAM resources in this module"
  type        = map(string)
  default     = {}
}
