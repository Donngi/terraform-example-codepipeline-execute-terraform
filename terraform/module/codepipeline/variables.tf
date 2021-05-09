variable "source_repository_name" {
  type = string
}

variable "source_repository_arn" {
  type = string
}

variable "source_branch_name" {
  type = string
}

variable "artifact_store_name" {
  type = string
}

variable "terraform_path" {
  type = string
}

variable "backend_s3_arn" {
  type = string
}

variable "backend_lock_dynamodb_arn" {
  type = string
}
