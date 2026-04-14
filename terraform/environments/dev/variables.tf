variable "app_id" {
  description = "Application identifier used for naming and tagging resources"
  type        = string
  default     = "ai-agent-on-aws"
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "model" {
  description = "Bedrock foundation model ID to use for the agent"
  type        = string
  default     = "eu.amazon.nova-pro-v1:0"
}

variable "agent_instructions" {
  description = "Instructions that define the agent's behavior and purpose"
  type        = string
  default     = "You are a helpful AI assistant. Answer questions clearly and concisely. When you are unsure, say so rather than guessing."
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}