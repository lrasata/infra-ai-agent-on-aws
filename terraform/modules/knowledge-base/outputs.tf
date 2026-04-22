output "knowledge_base_id" {
  description = "The ID of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_arn" {
  description = "The ARN of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.this.arn
}

output "data_source_id" {
  description = "The ID of the S3 data source"
  value       = aws_bedrockagent_data_source.s3.data_source_id
}

output "collection_arn" {
  description = "The ARN of the OpenSearch Serverless collection"
  value       = aws_opensearchserverless_collection.this.arn
}
