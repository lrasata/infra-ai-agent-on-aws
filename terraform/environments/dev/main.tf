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
  region = var.region

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
  region             = var.region
  model              = var.model
  agent_instructions = var.agent_instructions
  env                = var.env
}

module "lambda_functions" {
  source = "../../modules/lambda_function"

  # for_each to loop over lambda_configs to set up s3_ingestion and query_document lambdas
  for_each = local.lambda_configs

  # Pass common variables
  environment = var.env
  app_id      = var.app_id

  # Pass variables specific to the current iteration (key is the map key, value is the map content)
  lambda_name           = each.value.base_name
  source_dir            = each.value.source_dir
  handler_file          = each.value.handler_file
  runtime               = each.value.runtime
  iam_policy_statements = each.value.iam_policy_statements

}