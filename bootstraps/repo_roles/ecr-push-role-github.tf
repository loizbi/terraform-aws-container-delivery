# Creating the IAM policy for GitHub Actions
data "aws_iam_policy_document" "ecr_push_github_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # The principal is the OIDC provider for GitHub Actions
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # The request must come from the GitHub Actions OIDC provider
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    # The request must come from the specified GitHub repository & branch
    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      
      # GitHub OIDC immutable subject format
      values = [
        "repo:${var.ecr_github_org}@${var.ecr_github_owner_id}/${var.ecr_github_repo_name}@${var.ecr_github_repo_id}:ref:refs/heads/${var.ecr_push_github_branch}"
      ]
      
    }
  }
}

# Create the IAM role for GitHub Actions
resource "aws_iam_role" "ecr_push_github_role" {
  name               = "${var.ecr_role}-push-role"
  assume_role_policy = data.aws_iam_policy_document.ecr_push_github_assume_role.json
}

# Create the IAM policy for GitHub Actions
data "aws_iam_policy_document" "ecr_push_github_policy" {

  # Allow GitHub Actions to manage ECR
  statement {
    effect = "Allow"

    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]

    resources = [
      "${aws_ecr_repository.ecr_repo.arn}",
      "${aws_ecr_repository.ecr_repo.arn}/*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }
}

# Deploy the IAM policy for GitHub Actions
resource "aws_iam_policy" "ecr_push_github_deploy" {
  name        = "${var.ecr_role}-push-policy"
  description = "Policy used for deployments on CI"
  policy      = data.aws_iam_policy_document.ecr_push_github_policy.json
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecr_push_github_deploy" {
  role       = aws_iam_role.ecr_push_github_role.name
  policy_arn = aws_iam_policy.ecr_push_github_deploy.arn
}