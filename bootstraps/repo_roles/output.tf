
output "AWS_ARN_PUSH_ROLE" {
  value = aws_iam_role.ecr_push_github_role.arn
}

output "AWS_ARN_PROMOTE_ROLE" {
  value = aws_iam_role.ecr_promote_github_role.arn
}

output "AWS_REPO_URI" {
  value = aws_ecr_repository.ecr_repo.repository_url
}