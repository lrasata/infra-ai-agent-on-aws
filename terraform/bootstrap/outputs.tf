output "state_bucket_name" {
  description = "S3 bucket holding Terraform state (derived automatically in CI from app_id + account ID)"
  value       = aws_s3_bucket.state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table used for state locking (derived automatically in CI from app_id)"
  value       = aws_dynamodb_table.locks.name
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN GitHub Actions secret"
  value       = aws_iam_role.github_actions.arn
}
