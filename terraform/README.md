# Infrastructure

Terraform modules provisioning the AWS resources the gateway writes validated artifacts to.

## Structure

```
terraform/
  environments/
    dev/          Dev environment — main.tf, variables.tf, outputs.tf, backend.tf
  modules/
    iam/          IAM role + least-privilege S3 upload policy
    s3/           S3 bucket with versioning, SSE, and bucket policy
```

## What gets created

- **IAM role** — assumable by EC2, grants `s3:PutObject` and `s3:ListBucket`
  scoped to `<bucket>/validated/*` only
- **S3 bucket** — versioning enabled, AES-256 SSE, public access blocked,
  bucket policy denies uploads from any principal other than the gateway role

## Local validation (no AWS credentials needed)

```bash
cd terraform/environments/dev
terraform init -backend=false
terraform validate
```

## Deploy

```bash
cd terraform/environments/dev
terraform init
terraform workspace new dev
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
