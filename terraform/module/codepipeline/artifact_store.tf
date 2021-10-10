# ------------------------------------------------------------
# S3
# ------------------------------------------------------------
resource "aws_s3_bucket" "codepipeline_artifact" {
  bucket = var.artifact_store_name
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifact" {
  bucket = aws_s3_bucket.codepipeline_artifact.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# KMS
# ------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "codepipeline_artifact" {
  description = "KMS key for CodePipeline artifact store"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "*"
        Resource = "*"
      },
    ]
  })

  enable_key_rotation = true
}

resource "aws_kms_alias" "codepipeline_artifact" {
  name          = "alias/CodeArtifactKey"
  target_key_id = aws_kms_key.codepipeline_artifact.key_id
}
