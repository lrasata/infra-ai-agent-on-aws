data "aws_caller_identity" "current" {}

locals {
  vector_bucket_name = "${var.app_id}-${var.env}"
  index_name         = "${var.app_id}-${var.env}-index"
}

# ── S3 Vector bucket (stores the embeddings) ─────────────────────────────────

resource "aws_s3vectors_vector_bucket" "s3vectors_bucket" {
  vector_bucket_name = local.vector_bucket_name
}

resource "aws_s3vectors_index" "s3vectors_index" {
  vector_bucket_name = aws_s3vectors_vector_bucket.s3vectors_bucket.vector_bucket_name
  index_name         = local.index_name
  data_type          = "float32"
  dimension          = var.embedding_dimensions
  distance_metric    = "cosine"
}

# ── IAM role for the Knowledge Base ──────────────────────────────────────────

resource "aws_iam_role" "knowledge_base" {
  name = "${var.app_id}-${var.env}-kb-role"

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
            "aws:SourceArn" = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
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

resource "aws_iam_role_policy" "knowledge_base" {
  name = "${var.app_id}-${var.env}-kb-policy"
  role = aws_iam_role.knowledge_base.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "arn:aws:bedrock:${var.region}::foundation-model/${var.embedding_model}"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3vectors:*"]
        Resource = [
          aws_s3vectors_vector_bucket.s3vectors_bucket.vector_bucket_arn,
          "${aws_s3vectors_vector_bucket.s3vectors_bucket.vector_bucket_arn}/index/*",
        ]
      }
    ]
  })
}

# ── Knowledge Base ────────────────────────────────────────────────────────────

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "${var.app_id}-${var.env}-kb"
  role_arn = aws_iam_role.knowledge_base.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.region}::foundation-model/${var.embedding_model}"
    }
  }

  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.s3vectors_index.index_arn
    }
  }

  tags = {
    AppId       = var.app_id
    Environment = var.env
  }
}

# ── S3 data source ────────────────────────────────────────────────────────────

resource "aws_bedrockagent_data_source" "s3" {
  name              = "${var.app_id}-${var.env}-s3-source"
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.bucket_arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
