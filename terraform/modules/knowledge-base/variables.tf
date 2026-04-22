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

variable "bucket_arn" {
  description = "ARN of the S3 bucket that holds knowledge base documents"
  type        = string
}

variable "bucket_id" {
  description = "Name / ID of the S3 bucket"
  type        = string
}

variable "embedding_model" {
  description = "Bedrock embedding model ID used to vectorise documents"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimensions" {
  description = "Vector dimensions produced by the embedding model (1024 for Titan Embed V2, 1536 for V1)"
  type        = number
  default     = 1024
}
