terraform {
  backend "s3" {
    bucket       = "example-terraform-bootstraps-dev-eu-central-1"
    key          = "repo_roles/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}