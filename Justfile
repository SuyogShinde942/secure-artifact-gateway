tf_dir := "terraform/environments/dev"
gw_dir  := "gateway"
bin     := gw_dir / "gateway"
artifact := gw_dir / "testdata/artifact.txt"
artifact_sha := "1ff1e7529d4c1960db06639b5f78f707ea07833b502749d2d763bd7eccee1df9"
config_clean := gw_dir / "testdata/config_clean.yaml"
config_dirty := gw_dir / "testdata/config_dirty.yaml"
rules   := gw_dir / "rules.json"

default:
    @just --list

build:
    cd {{gw_dir}} && go build -o gateway .
    @echo "built: {{bin}}"

check-integrity: build
    ./{{bin}} -file {{artifact}} -sha256 {{artifact_sha}}

scan-clean: build
    ./{{bin}} -config {{config_clean}} -rules {{rules}}

scan-dirty: build
    ./{{bin}} -config {{config_dirty}} -rules {{rules}} || true

demo: check-integrity scan-clean scan-dirty

tf-init:
    cd {{tf_dir}} && terraform init -backend=false

tf-validate: tf-init
    cd {{tf_dir}} && terraform validate

tf-plan:
    cd {{tf_dir}} && terraform plan -var-file=terraform.tfvars

tf-graph: tf-init
    cd {{tf_dir}} && terraform graph | grep -v '"provider\[' | grep -v '^}'

all: demo tf-validate
    @echo "all checks passed"
