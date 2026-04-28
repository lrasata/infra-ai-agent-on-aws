variable "app_id" {
  description = "Application identifier used for naming and tagging resources"
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
