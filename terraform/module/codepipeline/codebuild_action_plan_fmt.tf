# ------------------------------------------------------------
# CodeBuild
# ------------------------------------------------------------
resource "aws_codebuild_project" "plan_fmt" {
  name         = "TerraformPlanFmt"
  description  = "Project to execute terraform plan and fmt"
  service_role = aws_iam_role.codebuild_project_plan_fmt.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/buildspec_action_plan_fmt.yml", {
      TERRAFORM_PATH = var.terraform_path,
    })
  }
}

# ------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------
resource "aws_iam_role" "codebuild_project_plan_fmt" {
  name = "TerraformCodeBuildProjectPlanFmtRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codebuild_project_plan_fmt" {
  name        = "TerraformCodeBuildActionPlanAndFmtPolicy"
  description = "Allow CodeBuild to access to CloudWatch, Artifact store and backend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowWriteLogToCloudWatchLogs"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      },
      {
        Sid = "AllowArtifactStoreAccess"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.codepipeline_artifact.arn}/*",
        ]
      },
      {
        Sid = "AllowUseKMSKey"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDatakey*"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.codepipeline_artifact.arn
      },
      {
        Sid = "AllowListBackendS3"
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = var.backend_s3_arn
      },
      {
        Sid = "AllowAccessToBackendS3"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "${var.backend_s3_arn}/*"
      },
      {
        Sid = "AllowAccessToBackendDynamoDBLockTable"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = var.backend_lock_dynamodb_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_project_plan_fmt" {
  role       = aws_iam_role.codebuild_project_plan_fmt.name
  policy_arn = aws_iam_policy.codebuild_project_plan_fmt.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_project_plan_fmt_read_only" {
  role       = aws_iam_role.codebuild_project_plan_fmt.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
