# Gateway CLI

## Build

```bash
cd gateway
go build -o gateway .
```

## Run

| Flag | Description |
|---|---|
| `-file` | Path to the artifact to verify |
| `-sha256` | Expected SHA-256 hex digest (64 chars) |
| `-config` | Path to the config file to scan for secrets |
| `-rules` | Path to the rules file (default: `rules.json`) |

**Integrity check:**
```bash
HASH=$(shasum -a 256 testdata/artifact.txt | awk '{print $1}')
./gateway -file testdata/artifact.txt -sha256 "$HASH"
```

**Secrets scan:**
```bash
./gateway -config testdata/config_clean.yaml -rules rules.json
```

**Both together:**
```bash
./gateway \
  -file   testdata/artifact.txt \
  -sha256 "$HASH" \
  -config testdata/config_clean.yaml \
  -rules  rules.json
```

Exits `0` on success, `1` on failure. Pipelines use this exit code as a hard gate.

## CI/CD Integration

### GitHub Actions

```yaml
- name: Security gate
  uses: docker://suyog942/secure-gateway:1.0.0
  with:
    args: >-
      -file   my-service
      -sha256 "$(cat my-service.sha256)"
      -config deploy/config.yaml
      -rules  rules.json
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
    - shasum -a 256 my-service | awk '{print $1}' > my-service.sha256
  artifacts:
    paths: [my-service, my-service.sha256]

security-gate:
  stage: gate
  image: suyog942/secure-gateway:1.0.0
  script:
    - gateway
        -file   my-service
        -sha256 "$(cat my-service.sha256)"
        -config deploy/config.yaml
        -rules  rules.json

promote:
  stage: promote
  script:
    - aws s3 cp my-service s3://my-bucket/validated/
  needs: [security-gate]
```
