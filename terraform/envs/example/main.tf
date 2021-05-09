module "codepipeline" {
  source                    = "../../module/codepipeline"
  source_repository_name    = "YOUR_TERRAFORM_REPOSITORY_NAME_HERE!!!"   # Repository name to be built
  source_repository_arn     = "YOUR_TERRAFORM_REPOSITORY_ARN_HERE!!!"    # Repository arn to be built
  source_branch_name        = "YOUR_TERRAFORM_REPOSITORY_BRANCH_HERE!!!" # Branch to be built
  artifact_store_name       = "YOUR_ARTIFACT_STORE_S3_NAME_HERE!!!"      # Artifact store (S3) name
  terraform_path            = "YOUR_TERRAFORM_PATH_HERE!!!"              # Path where terraform commands will be executed
  backend_s3_arn            = "YOUR_BACKEND_S3_ARN_HERE!!!"              # Backend S3 for terraform state file
  backend_lock_dynamodb_arn = "YOUR_DYNAMODB_LOCK_TABLE_ARN_HERE"        # Backend lock table 
}
