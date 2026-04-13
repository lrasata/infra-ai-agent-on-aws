data "aws_caller_identity" "current" {}

# IAM role assumed by the Bedrock Agent
resource "aws_iam_role" "agent_iam_role" {
  name = "${var.app_id}-${var.env}-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agent/*"
          }
        }
      }
    ]
  })

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}

# Policy allowing the agent to invoke via inference profile and underlying foundation model
resource "aws_iam_role_policy" "agent_model_invocation" {
  name = "${var.app_id}-${var.env}-model-invocation"
  role = aws_iam_role.agent_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "bedrock:InvokeModel"
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::inference-profile/${var.model}",
          "arn:aws:bedrock:*::foundation-model/*"
        ]
      }
    ]
  })
}

# Bedrock Agent
resource "aws_bedrockagent_agent" "this" {
  agent_name              = "${var.app_id}-${var.env}"
  agent_resource_role_arn = aws_iam_role.agent_iam_role.arn
  foundation_model        = var.model
  instruction             = var.agent_instructions
  idle_session_ttl_in_seconds = 600

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}

# Agent alias pointing to the DRAFT version
resource "aws_bedrockagent_agent_alias" "draft" {
  agent_id         = aws_bedrockagent_agent.this.agent_id
  agent_alias_name = "draft"

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}