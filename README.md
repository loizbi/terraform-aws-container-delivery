# Terraform AWS Container Delivery

This repository demonstrates an AWS CI/CD pipeline with Terraform bootstrapping the resources GitHub Actions needs: an S3 state bucket, an ECR repository and GitHub OIDC roles. Actions builds and scans an illustrative Docker webapp on `validation`, pushes the image to ECR under its commit SHA, then promotes that same image after a merged pull request to `main` and approval in the `production` Environment.

The webapp and Compose files are sample workload material. Terraform does not provision application compute or deploy the app to a runtime platform.

**Technologies:** Terraform · AWS (S3, ECR, IAM/OIDC) · GitHub Actions · Trivy · Docker

## Requirements

- AWS account, AWS CLI, Terraform CLI, and GitHub CLI.
- GitHub Actions enabled, with permission to configure repository variables, Environments, and branch protection.
- `validation` and `main` branches in the repository. The OIDC trust policies use GitHub's immutable owner and repository IDs.
- Docker is needed only to run the illustrative webapp locally.

## Create the Terraform State Bucket

Authenticate to AWS with the CLI. Navigate to `bootstraps/backend`. The S3 backend block in `main.tf` must be commented out when creating the bucket for the first time, allowing Terraform to initialize with a local state file. Run:

```sh
cd bootstraps/backend
terraform init
terraform apply
```

Then uncomment the S3 backend block, set it to the bucket name you created, and run `terraform init` again. Confirm migration of the local state to S3 with `terraform state list`.

## Create the ECR Repository and GitHub OIDC Roles

From `bootstraps/repo_roles`, set the backend bucket in `backend.tf`. Update `terraform.tfvars` with the AWS region, GitHub organization and repository IDs, validation and promotion branches, and role name. GitHub OIDC uses immutable owner and repository IDs. From your repository, get them with:

```sh
gh api repos/<OWNER>/<REPO> --jq '"owner_id=\(.owner.id) repo_id=\(.id)"'
```

Then create the repository and roles:

```sh
terraform init
terraform apply
```

Terraform outputs `AWS_ARN_PUSH_ROLE`, `AWS_ARN_PROMOTE_ROLE` and `AWS_REPO_URI`. The validation role trusts the configured validation branch. The promotion role trusts the `production` Environment and configured promotion branch.

## Configure the GitHub Repository

Navigate to **Settings → Secrets and variables → Actions → Variables** and add:

- `AWS_ARN_PUSH_ROLE` with the matching Terraform output.
- `AWS_ARN_PROMOTE_ROLE` with the matching Terraform output.
- When troubleshooting, add `ACTIONS_STEP_DEBUG` with the value `true` to enable step debug logging. Remove it or set it to `false` when finished.

## Configure Production Protections

Create a GitHub Environment named `production`, require reviewer approval, and restrict deployments to `main`. Protect `main` with required pull request reviews and checks; Environment approval happens after merge and protect image promotion.

## Configure the CI/CD Pipeline

The workflows use the sample app in `webapp/` as the image build context:

1. A push to `validation` that changes files under `webapp/` builds the image, scans for critical and high vulnerabilities, and pushes it to ECR with the commit SHA as an immutable tag.
2. A pull request closed as merged into `main` starts the promotion job. After production Environment approval, it reads the manifest tagged with the PR head SHA and adds the mutable `latest` tag to that same image.

The PR head commit must be the same commit the validation workflow pushed to ECR. A promotion fails if that SHA tag is not present.

## Run the WebApp Locally (Optional)
Copy `webapp/.env.example` to `webapp/.env` and `docker-compose.example.yml` to `docker-compose.yml`.
Set a local `DB_PASSWORD` for testing. Production deployments will receive it from a secret manager.

### Build locally

```sh
docker compose up -d
docker compose ps
```

### Pull from ECR
Set `ECR_URL` to your ECR repository URI and `ECR_TAG` to the image tag in `.env`.
Authenticate Docker to your ECR registry, see `docker-compose.yml` for how to switch from a local build to an ECR image and then start the services from `webapp/`:

```sh
aws ecr get-login-password --region <AWS_REGION> \
  | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

docker compose pull
docker compose up -d
```

With the example `PORT=100`, open `http://localhost:10010`. Stop the services with:

```sh
docker compose down
```

The PostgreSQL volume is retained. To remove it and its local data, run `docker compose down -v`.

## Push to validation and Open a Pull Request to main

Push a change under `webapp/` to `validation` and confirm the image build, scan, and ECR push succeed. Open a pull request from the validated commit to `main`. After required PR review and merge, approve the promotion job in the `production` Environment.

## Destroy Infrastructure

### Destroy the GitHub OIDC Roles and Amazon Elastic Container Registry

Navigate to `bootstraps/repo_roles` and run:

```sh
terraform destroy
```

The ECR repository has `prevent_destroy = true`, so Terraform blocks a full destroy until that guard is deliberately removed. The repository must also be empty unless `force_delete = true` is configured and applied.

### Destroy the State Bucket

> ⚠️ **Warning:** Back up the Terraform state before proceeding. Destroying the S3 bucket permanently deletes all stored objects and versions, including any state backups.

The bucket also stores the `repo_roles` Terraform state. Migrate or back up that state before destroying the bucket. From `bootstraps/backend`, comment out the S3 backend configuration in `main.tf` and migrate the state locally:

```sh
terraform init -migrate-state
```

Verify the local state with `terraform state list` before proceeding. In `main.tf`, set `prevent_destroy = false` in the `lifecycle` block for `aws_s3_bucket.terraform_state` and set `force_destroy = true`. This allows Terraform to delete the S3 bucket and its object versions. Run:

```sh
terraform init
terraform apply
terraform destroy
```