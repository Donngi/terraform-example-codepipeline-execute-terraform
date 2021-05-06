# ------------------------------------------------------------
# CodeBuild
# ------------------------------------------------------------
resource "aws_codebuild_project" "apply" {
  name         = "TerraformApply"
  description  = "Project to execute terraform apply"
  service_role = aws_iam_role.codebuild_project_apply.arn

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
    buildspec = templatefile("${path.module}/buildspec_action_apply.yml", {
      TERRAFORM_PATH = var.terraform_path,
    })
  }
}

# ------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------
resource "aws_iam_role" "codebuild_project_apply" {
  name = "TerraformCodeBuildProjectApplyRole"

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

resource "aws_iam_role_policy_attachment" "codebuild_project_apply_power_user" {
  role       = aws_iam_role.codebuild_project_apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_project_apply_iam_full_access" {
  role       = aws_iam_role.codebuild_project_apply.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}
