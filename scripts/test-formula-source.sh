#!/usr/bin/env bash
set -euo pipefail

root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

ruby "${root_directory}/scripts/render-stack-formula.rb" \
  "${root_directory}/metadata/stack-release.json" >"${temporary_directory}/stack.rb"

cmp "${temporary_directory}/stack.rb" "${root_directory}/Formula/stack.rb"
ruby -c "${root_directory}/Formula/stack.rb" >/dev/null

printf '%s\n' '{}' >"${temporary_directory}/invalid.json"
if ruby "${root_directory}/scripts/render-stack-formula.rb" "${temporary_directory}/invalid.json" >/dev/null 2>&1
then
  echo "renderer accepted invalid metadata" >&2
  exit 1
fi
