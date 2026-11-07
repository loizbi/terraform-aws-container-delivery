terraform {
  #############################################################
  ## Run terraform apply (with local backend) & uncomment the S3 backend configuration below
  ## Initialize Terraform to copy existing state to the new backend - terraform init
  ## Verify - terraform state list
  #############################################################
  #backend "s3" {
  #  bucket         = "example-terraform-bootstraps-dev-eu-central-1"
  #  key            = "backend/terraform.tfstate"
  #  region         = "eu-central-1"
  #  use_lockfile   = true
  #  encrypt        = true
  #}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.16.0"
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "example-terraform-bootstraps-dev-eu-central-1"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}