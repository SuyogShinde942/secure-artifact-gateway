output "role_arn" {
  description = "ARN of the Gateway IAM role"
  value       = aws_iam_role.gateway.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.gateway.name
}

output "policy_arn" {
  description = "ARN of the artifact upload IAM policy"
  value       = aws_iam_policy.artifact_upload.arn
}
