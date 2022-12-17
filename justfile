set shell := ["bash", "-euo", "pipefail", "-c"]
set export
set positional-arguments

default:
  @just --list

# Build the image
build:
  #!/usr/bin/env bash
  set -euxo pipefail
  skaffold build