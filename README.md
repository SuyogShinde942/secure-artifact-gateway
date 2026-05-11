# secure-gateway

A CLI security gate that verifies artifact integrity (SHA-256) and scans
configuration files for leaked secrets before they are promoted through a pipeline.

---

## Prerequisites

- Go 1.21 or later
- `sha256sum` (Linux) or `shasum -a 256` (macOS) for computing hashes locally
- Terraform 1.6+ (infrastructure only)
- AWS credentials with permission to run `terraform apply` (infrastructure only)

---

## Build

```bash
cd gateway
go build -o gateway .
```

This produces a single static binary called `gateway` inside the `gateway/` directory.

---

## Run

Run from inside the `gateway/` directory.

The tool accepts four flags:

| Flag       | Required              | Description                                  |
|------------|-----------------------|----------------------------------------------|
| `--file`   | With `--sha256`       | Path to the artifact to verify               |
| `--sha256` | With `--file`         | Expected SHA-256 hex digest (64 characters)  |
| `--config` | No (but recommended)  | Path to the config file to scan for secrets  |
| `--rules`  | No (default: rules.json) | Path to the rules file                    |

**Integrity check only:**
```bash
HASH=$(sha256sum testdata/artifact.txt | awk '{print $1}')
./gateway --file testdata/artifact.txt --sha256 "$HASH"
```

**Secret scan only:**
```bash
./gateway --config testdata/config_clean.yaml
```

**Both checks together:**
```bash
HASH=$(sha256sum testdata/artifact.txt | awk '{print $1}')
./gateway \
  --file   testdata/artifact.txt \
  --sha256 "$HASH" \
  --config testdata/config_clean.yaml
```

The tool exits `0` (success) when all checks pass and `1` (failure) when any check fails.
CI/CD pipelines use this exit code to decide whether to proceed or halt the pipeline.

---

## Rules file format

`rules.json` defines the regex patterns used for secret scanning:

```json
{
  "rules": [
    {
      "name": "password_assignment",
      "pattern": "(?i)(password|passwd|pwd)\\s*[:=]\\s*\\S{8,}"
    },
    {
      "name": "aws_access_key_id",
      "pattern": "AKIA[0-9A-Z]{16}"
    }
  ]
}
```

Add or remove rules without recompiling the binary.

---

## CI/CD Integration

The gateway runs as a blocking gate step. The pipeline only proceeds to artifact
promotion if the gateway exits `0`.

### GitHub Actions

```yaml
name: Build and Gate

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: "1.21"

      - name: Build application
        run: |
          go build -o my-service .
          # produce artifact and its hash
          sha256sum my-service | awk '{print $1}' > my-service.sha256

      - name: Build gateway
        run: go build -o gateway github.com/your-org/secure-gateway

      - name: Security gate
        run: |
          ./gateway \
            --file   my-service \
            --sha256 "$(cat my-service.sha256)" \
            --config deploy/config.yaml \
            --rules  rules.json

      - name: Upload validated artifact
        # This step only runs if the gate passed (exit 0)
        uses: actions/upload-artifact@v4
        with:
          name: my-service
          path: my-service
```

### GitLab CI

```yaml
stages:
  - build
  - gate
  - promote

build:
  stage: build
  script:
    - go build -o my-service .
    - sha256sum my-service | awk '{print $1}' > my-service.sha256
  artifacts:
    paths:
      - my-service
      - my-service.sha256

security-gate:
  stage: gate
  script:
    - go build -o gateway github.com/your-org/secure-gateway
    - |
      ./gateway \
        --file   my-service \
        --sha256 "$(cat my-service.sha256)" \
        --config deploy/config.yaml \
        --rules  rules.json
  # GitLab halts the pipeline automatically when this job exits non-zero

promote:
  stage: promote
  script:
    - aws s3 cp my-service s3://my-artifacts-bucket/validated/my-service
  needs:
    - security-gate   # only runs after the gate passes
```

---

## Infrastructure (Terraform)

The `terraform/` directory provisions the AWS environment the gateway operates in.

```
terraform/
  modules/
    iam/          IAM role + least-privilege S3 upload policy
    networking/   Security group allowing inbound only from build servers
  main.tf         Root module wiring both modules together
  variables.tf    Input variables
  outputs.tf      Role ARN, instance profile, and security group ID
  terraform.tfvars.example
```

### IAM (least privilege)

The `iam` module creates an IAM role with a single policy that grants:

- `s3:PutObject` on `<bucket>/<prefix>*` only — no `s3:*`, no other buckets
- `s3:ListBucket` scoped to the same prefix via a condition key

The role is assumable only by the EC2 service, meaning it can only be attached
to EC2 instances — not called by arbitrary IAM users or Lambda functions.

### Network security

The `networking` module creates a security group with:

- **Inbound**: TCP on `gateway_port` from `build_server_cidr` only (default `10.1.2.0/24`)
- **Outbound**: TCP 443 (HTTPS) to reach S3 and external registries
- No other inbound rules — SSH, ICMP, and all other ports are denied by default

### Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real values

terraform init
terraform plan
terraform apply
```

The outputs give you the instance profile name and security group ID to attach
to the EC2 instance or launch template that runs the gateway.
