
# Global Vars
variable "aws_region" {
  description = "Global AWS region where resources will be created"
  type        = string
}

# ECR Repo Vars
variable "ecr_repo_name" {
  description = "ECR - Repository name"
  type        = string
}

# ECR GitHub Repo Vars
variable "ecr_github_org" {
  description = "ECR - GitHub Organization name"
  type        = string
}

variable "ecr_github_repo_name" {
  description = "ECR - GitHub repository name"
  type        = string
}

variable "ecr_github_repo_id" {
  description = "ECR - GitHub repository ID"
  type        = string
}

variable "ecr_github_owner_id" {
  description = "ECR - GitHub repository owner ID"
  type        = string
}

variable "ecr_push_github_branch" {
  description = "ECR - GitHub branch name"
  type        = string
}

variable "ecr_promote_github_branch" {
  description = "ECR - GitHub branch name"
  type        = string
}

variable "ecr_role" {
  description = "ECR - Role Name"
  type        = string
}