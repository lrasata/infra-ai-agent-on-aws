resource "aws_s3_bucket" "knowledge_base_bucket" {
  bucket = "${var.environment}-${var.app_id}-${var.knowledge_base_bucket_name}"

  tags = {
    Name        = "${var.environment}-${var.app_id}-${var.knowledge_base_bucket_name}"
    Environment = var.environment
    App         = var.app_id
    Description = "Bucket for storing files for knowledge base"
  }
}


# ============================================================================
# UPLOADS BUCKET CONFIGURATION
# ============================================================================
# Versioning
resource "aws_s3_bucket_versioning" "uploads_versioning" {
  bucket = aws_s3_bucket.knowledge_base_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to uploads bucket
resource "aws_s3_bucket_public_access_block" "uploads_public_access" {
  bucket = aws_s3_bucket.knowledge_base_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
