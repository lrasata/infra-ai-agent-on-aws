output "uploads_bucket_id" {
  description = "ID (name) of the uploads S3 bucket"
  value       = aws_s3_bucket.knowledge_base_bucket.id
}

output "uploads_bucket_arn" {
  description = "ARN of the uploads S3 bucket"
  value       = aws_s3_bucket.knowledge_base_bucket.arn
}

output "uploads_bucket_regional_domain_name" {
  description = "Regional domain name of the uploads bucket (for CloudFront)"
  value       = aws_s3_bucket.knowledge_base_bucket.bucket_regional_domain_name
}