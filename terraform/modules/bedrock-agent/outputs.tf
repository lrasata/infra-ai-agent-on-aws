output "agent_id" {
  description = "The ID of the Bedrock Agent"
  value       = aws_bedrockagent_agent.this.agent_id
}

output "agent_arn" {
  description = "The ARN of the Bedrock Agent"
  value       = aws_bedrockagent_agent.this.agent_arn
}

output "agent_alias_id" {
  description = "The ID of the draft agent alias"
  value       = aws_bedrockagent_agent_alias.draft.agent_alias_id
}

output "agent_alias_arn" {
  description = "The ARN of the draft agent alias"
  value       = aws_bedrockagent_agent_alias.draft.agent_alias_arn
}

output "agent_role_arn" {
  description = "The ARN of the IAM role used by the agent"
  value       = aws_iam_role.agent_iam_role.arn
}