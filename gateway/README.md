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
env:
  VERSION: "1.5.4"
  ARTIFACT: "clientapis-1.5.4.tgz"

steps:
  - name: Build and package
    run: |
      go build -o clientapis .
      tar -czf clientapis-${{ env.VERSION }}.tgz clientapis
      shasum -a 256 ${{ env.ARTIFACT }} | awk '{print $1}' > ${{ env.ARTIFACT }}.sha256

  - name: Security gate
    uses: docker://suyog942/secure-gateway:1.0.0
    with:
      args: >-
        -file   ${{ env.ARTIFACT }}
        -sha256 "$(cat ${{ env.ARTIFACT }}.sha256)"
        -config deploy/config.yaml
        -rules  rules.json

  - name: Promote validated artifact
    run: |
      aws s3 cp ${{ env.ARTIFACT }} s3://my-bucket/validated/${{ env.VERSION }}/${{ env.ARTIFACT }}
```

### GitLab CI

```yaml
variables:
  VERSION: "1.5.4"
  ARTIFACT: "clientapis-1.5.4.tgz"

stages:
  - build
  - gate
  - promote

build:
  stage: build
  script:
    - go build -o clientapis .
    - tar -czf $ARTIFACT clientapis
    - shasum -a 256 $ARTIFACT | awk '{print $1}' > $ARTIFACT.sha256
  artifacts:
    paths: [$ARTIFACT, "$ARTIFACT.sha256"]

security-gate:
  stage: gate
  image: suyog942/secure-gateway:1.0.0
  script:
    - gateway
        -file   $ARTIFACT
        -sha256 "$(cat $ARTIFACT.sha256)"
        -config deploy/config.yaml
        -rules  rules.json

promote:
  stage: promote
  script:
    - aws s3 cp $ARTIFACT s3://my-bucket/validated/$VERSION/$ARTIFACT
  needs: [security-gate]
```
