terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      AppId       = var.app_id
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}

module "bedrock_agent" {
  source = "../../modules/bedrock-agent"

  app_id             = var.app_id
  aws_region         = var.aws_region
  model              = var.model
  agent_instructions = var.agent_instructions
  env                = var.env
}