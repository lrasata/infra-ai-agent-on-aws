output "log_group_name" {
  description = "Name of the CloudWatch log group receiving Bedrock invocation logs"
  value       = aws_cloudwatch_log_group.bedrock.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.bedrock.arn
}

output "role_arn" {
  description = "ARN of the IAM role used by Bedrock to write logs"
  value       = aws_iam_role.bedrock_logging.arn
}
