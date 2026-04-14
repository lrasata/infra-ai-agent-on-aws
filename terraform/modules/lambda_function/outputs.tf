output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda_function.id
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda_function.arn
}

output "function_exec_role_arn" {
  value = aws_iam_role.lambda_exec_role.arn
}

