variable "app_id" {
  description = "Application identifier — must match the value used in environments/dev/terraform.tfvars"
  type        = string
  default     = "ops-assistant"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. liantsoa/infra-ai-agent-on-aws)"
  type        = string
}
