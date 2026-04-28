data "aws_caller_identity" "current" {}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "bedrock" {
  name              = "${var.app_id}-${var.env}-bedrock-logs"
  retention_in_days = var.retention_days

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}

# ── IAM policy: allow Bedrock to write log streams ────────────────────────────

resource "aws_iam_policy" "bedrock_logging" {
  name        = "${var.app_id}-${var.env}-bedrock-logs-policy"
  description = "Allows Bedrock to create log streams and put log events"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.bedrock.name}:log-stream:aws/bedrock/modelinvocations"
      }
    ]
  })
}

# ── IAM role: assumed by bedrock.amazonaws.com ────────────────────────────────

resource "aws_iam_role" "bedrock_logging" {
  name = "${var.app_id}-${var.env}-bedrock-logs-role"

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
            "aws:SourceArn" = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:*"
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

resource "aws_iam_role_policy_attachment" "bedrock_logging" {
  role       = aws_iam_role.bedrock_logging.name
  policy_arn = aws_iam_policy.bedrock_logging.arn
}

# ── Bedrock model invocation logging configuration ────────────────────────────

resource "aws_bedrock_model_invocation_logging_configuration" "this" {
  logging_config {
    embedding_data_delivery_enabled = true
    image_data_delivery_enabled     = true
    text_data_delivery_enabled      = true

    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock.name
      role_arn       = aws_iam_role.bedrock_logging.arn
    }
  }

  depends_on = [aws_iam_role_policy_attachment.bedrock_logging]
}
