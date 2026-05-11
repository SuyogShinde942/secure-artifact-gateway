variable "bucket_name" {
  description = "Name of the S3 artifacts bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters, lowercase, and contain only letters, numbers, and hyphens."
  }
}

variable "artifacts_prefix" {
  description = "S3 key prefix that validated artifacts are written under"
  type        = string
  default     = "validated/"

  validation {
    condition     = can(regex("^[^/].*/$", var.artifacts_prefix))
    error_message = "artifacts_prefix must not start with / and must end with /."
  }
}

variable "gateway_role_arn" {
  description = "ARN of the IAM role that is allowed to upload artifacts"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.gateway_role_arn))
    error_message = "gateway_role_arn must be a valid IAM role ARN."
  }
}

variable "block_public_acls" {
  description = "Block public ACLs on the bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies on the bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on the bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies on the bucket"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (aws:kms or AES256)"
  type        = string
  default     = "aws:kms"

  validation {
    condition     = contains(["aws:kms", "AES256"], var.sse_algorithm)
    error_message = "sse_algorithm must be either aws:kms or AES256."
  }
}

variable "bucket_key_enabled" {
  description = "Enable S3 bucket key to reduce KMS request costs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all S3 resources in this module"
  type        = map(string)
  default     = {}
}
