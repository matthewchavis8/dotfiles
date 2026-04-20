#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh <mac|linux> [flake-target]

Examples:
  ./bootstrap.sh mac
  ./bootstrap.sh mac my-hostname
  ./bootstrap.sh linux
  ./bootstrap.sh linux mchavis
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

platform="$1"
target="${2:-}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$platform" in
  mac)
    if [[ -z "$target" ]]; then
      target="bootstrap"
    fi

    sudo nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
      switch --flake "${repo_root}/nix/mac#${target}"
    ;;
  linux)
    if [[ -z "$target" ]]; then
      target="${USER}"
    fi

    nix run github:nix-community/home-manager -- \
      switch --flake "${repo_root}/nix/linux#${target}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
