output "agent_id" {
  description = "The ID of the Bedrock Agent"
  value       = module.bedrock_agent.agent_id
}

output "agent_arn" {
  description = "The ARN of the Bedrock Agent"
  value       = module.bedrock_agent.agent_arn
}

output "agent_alias_id" {
  description = "The ID of the draft agent alias"
  value       = module.bedrock_agent.agent_alias_id
}

output "agent_alias_arn" {
  description = "The ARN of the draft agent alias"
  value       = module.bedrock_agent.agent_alias_arn
}

output "agent_role_arn" {
  description = "The ARN of the IAM role used by the agent"
  value       = module.bedrock_agent.agent_role_arn
}

output "knowledge_base_id" {
  description = "The ID of the Bedrock Knowledge Base"
  value       = module.knowledge_base.knowledge_base_id
}

output "knowledge_base_arn" {
  description = "The ARN of the Bedrock Knowledge Base"
  value       = module.knowledge_base.knowledge_base_arn
}

output "kb_data_source_id" {
  description = "The ID of the S3 data source attached to the knowledge base"
  value       = module.knowledge_base.data_source_id
}