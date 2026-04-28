variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "knowledge_base_bucket_name" {
  description = "Base name for the uploads S3 bucket"
  type        = string
}

variable "app_id" {
  description = "Application identifier for tagging resources"
  type        = string
}