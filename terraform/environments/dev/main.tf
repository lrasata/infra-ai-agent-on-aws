terraform {
  required_version = ">= 1.5"

  # Backend values are passed via -backend-config in CI and locally via backend.hcl
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
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

module "s3" {
  source = "../../modules/s3"

  environment                = var.env
  app_id                     = var.app_id
  knowledge_base_bucket_name = var.knowledge_base_bucket_name
}

module "knowledge_base" {
  source = "../../modules/knowledge-base"

  app_id     = var.app_id
  env        = var.env
  region     = var.region
  bucket_arn = module.s3.uploads_bucket_arn
  bucket_id  = module.s3.uploads_bucket_id

  depends_on = [module.s3]
}

module "kb_sync_lambda" {
  source = "../../modules/lambda_function"

  environment  = var.env
  app_id       = var.app_id
  lambda_name  = "kb-sync"
  source_dir   = "${path.module}/../../src/lambda_functions/kb_sync"
  handler_file = "kb_sync.lambda_handler"
  runtime      = "python3.11"
  timeout      = 60

  environment_vars = {
    KNOWLEDGE_BASE_ID = module.knowledge_base.knowledge_base_id
    DATA_SOURCE_ID    = module.knowledge_base.data_source_id
  }

  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["bedrock:StartIngestionJob"]
      Resource = module.knowledge_base.knowledge_base_arn
    }
  ]

  depends_on = [module.knowledge_base]
}

resource "aws_lambda_permission" "allow_s3_invoke_kb_sync" {
  statement_id  = "AllowS3InvokeKbSync"
  action        = "lambda:InvokeFunction"
  function_name = module.kb_sync_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3.uploads_bucket_arn
}

resource "aws_s3_bucket_notification" "kb_sync" {
  bucket = module.s3.uploads_bucket_id

  lambda_function {
    lambda_function_arn = module.kb_sync_lambda.function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke_kb_sync]
}

module "bedrock_agent" {
  source = "../../modules/bedrock-agent"

  app_id             = var.app_id
  region             = var.region
  model              = var.model
  agent_instructions = var.agent_instructions
  env                = var.env

  knowledge_base_id  = module.knowledge_base.knowledge_base_id
  knowledge_base_arn = module.knowledge_base.knowledge_base_arn

  guardrail_id      = module.guardrails.guardrail_id
  guardrail_version = module.guardrails.guardrail_version

  action_groups = {
    ops_actions = {
      lambda_arn     = module.lambda_functions["ops_get_service_info"].function_arn
      description    = "Operations actions for getting service information"
      openapi_schema = file("${path.module}/schemas/services_actions.yaml")
    }
  }

  depends_on = [module.lambda_functions, module.knowledge_base, module.guardrails]
}

module "guardrails" {
  source = "../../modules/bedrock-guardrails"

  environment = var.env
  app_id      = var.app_id
}