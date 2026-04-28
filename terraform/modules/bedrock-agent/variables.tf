variable "app_id" {
  description = "Application identifier used for naming and tagging resources"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "model" {
  description = "Bedrock foundation model ID to use for the agent"
  type        = string
}

variable "agent_instructions" {
  description = "Instructions that define the agent's behavior and purpose"
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}

variable "enable_memory" {
  description = "Enable SESSION_SUMMARY memory so the agent can recall context across sessions"
  type        = bool
  default     = false
}

variable "memory_storage_days" {
  description = "Number of days to retain agent memory (1–365). Only used when enable_memory is true"
  type        = number
  default     = 30
}

variable "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base to associate with the agent"
  type        = string
}

variable "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base (used to grant the agent Retrieve permissions)"
  type        = string
}

variable "guardrail_id" {
  description = "ID of the Bedrock guardrail to attach to the agent. Leave empty to disable."
  type        = string
  default     = ""
}

variable "guardrail_version" {
  description = "Version of the Bedrock guardrail to enforce. Required when guardrail_id is set."
  type        = string
  default     = ""
}

variable "action_groups" {
  description = "Map of action groups to attach to the agent"
  type = map(object({
    lambda_arn     = string
    description    = string
    openapi_schema = string
  }))
  default = {}
}