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