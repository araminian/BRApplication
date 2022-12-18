set shell := ["bash", "-euo", "pipefail", "-c"]
set export
set positional-arguments

CI_DIR := "ci"

# Git
GIT_REV := `git rev-parse --short=16 HEAD`
GITHUB_USERNAME := "araminian"
GITHUB_TOKEN := env_var_or_default('RE_BOT',"")
GITOPS_REPO := "https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/araminian/gitops-manifests.git"
GITOPS_REPO_USER := "git@github.com:araminian/gitops-manifests.git"
GITOPS_DIR := CI_DIR +"/gitops"
GITOPS_FLAGS := "-C $GITOPS_DIR"



default:
  @just --list


# Sync generated manifests to gitops repo
apply ENVIRONMENT REGION: (plan ENVIRONMENT REGION)
  #!/usr/bin/env bash
  echo "Copying genrerated k8s manfiests for ${ENVIRONMENT} ${REGION} ..."
  MANIFEST_DIR=ci/rendered-manifests/${ENVIRONMENT}/${REGION}
  SERVICE_MANIFEST_DIR=$MANIFEST_DIR
  SERVICE_GITOPS_PATH="$GITOPS_DIR/rendered-manifests/"
  mkdir -p $SERVICE_GITOPS_PATH
  rsync -avhz --delete $SERVICE_MANIFEST_DIR/* $SERVICE_GITOPS_PATH

  git {{GITOPS_FLAGS}} config user.email 'rmin.aminian@gmail.com'
  git {{GITOPS_FLAGS}} config user.name 'GitHub Action'
  git {{GITOPS_FLAGS}} add .
  git {{GITOPS_FLAGS}} commit \
      --allow-empty \
      --author "BR CI <rmin.aminian@gmail.com>" \
      --message 'BR : new {{ENVIRONMENT}} release' \
      --message 'From BR application@{{GIT_REV}}'
  git {{GITOPS_FLAGS}} push origin HEAD:main

# Git Diff
gitops-repo-diff:
  #!/usr/bin/env bash
  git {{GITOPS_FLAGS}} diff --exit-code || true

# Clone GitOps repository
gitops-repo-clone:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf $GITOPS_DIR

    if [[ -z ${CI+x} ]]; then
      git clone --depth 1 {{GITOPS_REPO_USER}} $GITOPS_DIR/
    elif [[ $CI ]]; then
      git clone --depth 1 {{GITOPS_REPO}} $GITOPS_DIR/
    fi
    git {{GITOPS_FLAGS}} fetch --prune origin
    git {{GITOPS_FLAGS}} checkout --force origin/main

# Build the image
build:
  #!/usr/bin/env bash
  set -euxo pipefail
  skaffold build

plan ENVIRONMENT REGION:
  #!/usr/bin/env bash
  MANIFEST_DIR=ci/rendered-manifests/${ENVIRONMENT}/${REGION}
  mkdir -p $MANIFEST_DIR
  set -euxo pipefail
  skaffold render --digest-source=remote > $MANIFEST_DIR/manifest.yaml

