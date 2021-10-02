# ------------------------------------------------------------
# CodePipeline
# ------------------------------------------------------------
resource "aws_codepipeline" "sample" {
  name     = "SamplePipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.codepipeline_artifact.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_artifact"]
      configuration = {
        RepositoryName       = var.source_repository_name
        BranchName           = var.source_branch_name
        PollForSourceChanges = false
      }
      role_arn = aws_iam_role.codepipeline_action_source.arn
    }
  }

  stage {
    name = "PlanAndfmt"

    action {
      name            = "TerraformPlanAndFmt"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_artifact"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.plan_fmt.name
      }
      role_arn = aws_iam_role.codepipeline_action_plan_fmt.arn
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_artifact"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.apply.name
      }
      role_arn = aws_iam_role.codepipeline_action_apply.arn
    }
  }
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Service role
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  name = "TerraformCodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline" {
  name        = "TerraformCodePipelinePolicy"
  description = "Allow CodePipeline to access to CodeCommit, Artifact store and assume IAM roles declared at each action"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAssumeRole"
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Resource = [
          aws_iam_role.codepipeline_action_source.arn,
          aws_iam_role.codepipeline_action_plan_fmt.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Action role: Source
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline_action_source" {
  name = "TerraformCodePipelineActionSourceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.codepipeline.arn
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline_action_source" {
  name        = "TerraformCodePipelineActionSourcePolicy"
  description = "Allow CodePipeline to access to CodeCommit and Artifact store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCodeCommitAccess"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive",
          "codecommit:CancelUploadArchive"
        ]
        Effect = "Allow"
        Resource = [
          var.source_repository_arn
        ]
      },
      {
        Sid = "AllowArtifactStoreAccess"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_action_source" {
  role       = aws_iam_role.codepipeline_action_source.name
  policy_arn = aws_iam_policy.codepipeline_action_source.arn
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Action role: PlanAndFmt
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline_action_plan_fmt" {
  name = "TerraformCodePipelineActionPlanAndFmtRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.codepipeline.arn
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline_action_plan_fmt" {
  name        = "TerraformCodePipelineActionPlanAndFmtPolicy"
  description = "Allow CodePipeline to start or stop codebuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCodeBuildAccess"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_action_plan_fmt" {
  role       = aws_iam_role.codepipeline_action_plan_fmt.name
  policy_arn = aws_iam_policy.codepipeline_action_plan_fmt.arn
}

# ------------------------------------------------------------
# IAM Role - CodePipeline Action role: Apply
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline_action_apply" {
  name = "TerraformCodePipelineActionApplyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = aws_iam_role.codepipeline.arn
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipeline_action_apply" {
  name        = "TerraformCodePipelineActionApplyPolicy"
  description = "Allow CodePipeline to start or stop codebuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCodeBuildAccess"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_action_apply" {
  role       = aws_iam_role.codepipeline_action_apply.name
  policy_arn = aws_iam_policy.codepipeline_action_apply.arn
}
