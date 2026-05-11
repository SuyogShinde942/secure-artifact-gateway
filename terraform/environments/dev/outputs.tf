output "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket"
  value       = module.s3.bucket_name
}

output "artifacts_bucket_arn" {
  description = "ARN of the artifacts S3 bucket"
  value       = module.s3.bucket_arn
}

output "gateway_role_arn" {
  description = "ARN of the Gateway IAM role"
  value       = module.iam.role_arn
}

output "gateway_instance_profile" {
  description = "Name of the IAM instance profile — attach this to the build server EC2"
  value       = module.iam.instance_profile_name
}
