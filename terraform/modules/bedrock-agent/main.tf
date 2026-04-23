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
            "aws:SourceArn" = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:agent/*"
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
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.model}",
          "arn:aws:bedrock:*::foundation-model/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:GetFoundationModel",
          "bedrock:GetInferenceProfile",
          "bedrock:ListInferenceProfiles"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeAgent",
          "bedrock:InvokeAgentWithResponseStream"
        ]
        Resource = "*"
      }
    ]
  })
}

# Bedrock Agent
resource "aws_bedrockagent_agent" "this" {
  agent_name                  = "${var.app_id}-${var.env}"
  agent_resource_role_arn     = aws_iam_role.agent_iam_role.arn
  foundation_model            = var.model
  instruction                 = var.agent_instructions
  idle_session_ttl_in_seconds = 600

  dynamic "memory_configuration" {
    for_each = var.enable_memory ? [1] : []
    content {
      enabled_memory_types = ["SESSION_SUMMARY"]
      storage_days         = var.memory_storage_days
    }
  }

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}

# Allow Bedrock agent to invoke each action group Lambda
resource "aws_lambda_permission" "agent_invoke" {
  for_each = var.action_groups

  statement_id  = "AllowBedrockAgentInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "bedrock.amazonaws.com"
  source_arn    = aws_bedrockagent_agent.this.agent_arn
}

# Allow the agent IAM role to call Lambda
resource "aws_iam_role_policy" "agent_lambda_invoke" {
  count = length(var.action_groups) > 0 ? 1 : 0

  name = "${var.app_id}-${var.env}-lambda-invoke"
  role = aws_iam_role.agent_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = [for ag in var.action_groups : ag.lambda_arn]
    }]
  })
}

# Action groups
resource "aws_bedrockagent_agent_action_group" "this" {
  for_each = var.action_groups

  agent_id          = aws_bedrockagent_agent.this.agent_id
  agent_version     = "DRAFT"
  action_group_name = each.key
  description       = each.value.description
  prepare_agent     = false

  action_group_executor {
    lambda = each.value.lambda_arn
  }

  api_schema {
    payload = each.value.openapi_schema
  }

  # Bedrock rejects DELETE on an ENABLED action group. UpdateAgentActionGroup to DISABLED
  # also requires the full schema, which isn't available in a destroy provisioner.
  # Workaround: delete it ourselves with --skip-resource-in-use-check; Terraform's own
  # subsequent delete call will get a 404 and treat it as success.
  provisioner "local-exec" {
    when    = destroy
    command = "aws bedrock-agent delete-agent-action-group --agent-id ${self.agent_id} --agent-version DRAFT --action-group-id ${self.action_group_id} --skip-resource-in-use-check"
  }
}

# Allow the agent to query the knowledge base
resource "aws_iam_role_policy" "agent_kb_retrieve" {
  name = "${var.app_id}-${var.env}-kb-retrieve"
  role = aws_iam_role.agent_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:Retrieve"]
      Resource = var.knowledge_base_arn
    }]
  })
}

# Associate the knowledge base with the agent
resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  agent_id             = aws_bedrockagent_agent.this.agent_id
  agent_version        = "DRAFT"
  knowledge_base_id    = var.knowledge_base_id
  knowledge_base_state = "ENABLED"
  description          = "S3-backed knowledge base for RAG"
}

# The KB association triggers a PrepareAgent call internally but doesn't wait for it to finish.
# Poll until the agent leaves PREPARING state before creating the alias.
resource "null_resource" "wait_agent_ready" {
  triggers = {
    kb_association = aws_bedrockagent_agent_knowledge_base_association.this.knowledge_base_id
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      while true; do
        STATUS=$(aws bedrock-agent get-agent \
          --agent-id ${aws_bedrockagent_agent.this.agent_id} \
          --region ${var.region} \
          --query 'agent.agentStatus' \
          --output text 2>/dev/null)
        [ "$STATUS" != "PREPARING" ] && break
        sleep 5
      done
    EOT
  }
}

# Agent alias pointing to the DRAFT version
resource "aws_bedrockagent_agent_alias" "draft" {
  agent_id         = aws_bedrockagent_agent.this.agent_id
  agent_alias_name = "draft"

  depends_on = [
    aws_bedrockagent_agent_action_group.this,
    null_resource.wait_agent_ready,
  ]

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}