# secure-artifact-gateway

A CLI security gate that verifies SHA-256 artifact integrity and scans
configuration files for hardcoded secrets before artifacts are promoted
through a pipeline.

- [Gateway CLI](./gateway/README.md) — build, run, and CI/CD integration
- [Infrastructure](./terraform/README.md) — Terraform modules for IAM and S3
