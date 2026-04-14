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

variable "action_groups" {
  description = "Map of action groups to attach to the agent"
  type = map(object({
    lambda_arn     = string
    description    = string
    openapi_schema = string
  }))
  default = {}
}