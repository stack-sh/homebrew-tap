#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "usage: scripts/update-stack-formula.sh VERSION" >&2
  exit 2
fi

for command_name in gh ruby
do
  if ! command -v "${command_name}" >/dev/null 2>&1
  then
    echo "${command_name} is required" >&2
    exit 1
  fi
done

version="$1"
tag="v${version}"
repository="stack-sh/cli"
source_ref="refs/tags/${tag}"
workflow="stack-sh/cli/.github/workflows/release.yaml"
root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

release_state="$(gh release view "${tag}" --repo "${repository}" --json isDraft,isPrerelease,tagName --jq '[.tagName, .isDraft, .isPrerelease] | @tsv')"
if [[ "${release_state}" != "${tag}"$'\t'"false"$'\t'"false" ]]
then
  echo "${tag} must be a published stable release" >&2
  exit 1
fi

manifest_name="stack-v${version}-release-manifest.json"
checksums_name="stack-v${version}-checksums.txt"
gh release download "${tag}" --repo "${repository}" --dir "${temporary_directory}" \
  --pattern "${manifest_name}" \
  --pattern "${checksums_name}"

source_commit="$(ruby -rjson -e '
  manifest = JSON.parse(File.read(ARGV.fetch(0)))
  expected_version = ARGV.fetch(1)
  abort "manifest version mismatch" unless manifest["version"] == expected_version
  abort "manifest tag mismatch" unless manifest["tag"] == "v#{expected_version}"
  abort "manifest repository mismatch" unless manifest.dig("source", "repository") == "stack-sh/cli"
  abort "manifest source commit is invalid" unless manifest.dig("source", "commit")&.match?(/\A[0-9a-f]{40}\z/)
  abort "manifest workflow mismatch" unless manifest["builderWorkflow"] == "stack-sh/cli/.github/workflows/release.yaml"
  abort "GitHub Release is not verified" unless manifest.fetch("verifiedChannels").include?("github-release")
  puts manifest.dig("source", "commit")
' "${temporary_directory}/${manifest_name}" "${version}")"

targets=(
  aarch64-apple-darwin
  x86_64-apple-darwin
  aarch64-unknown-linux-gnu
  x86_64-unknown-linux-gnu
)
digests=()

for target in "${targets[@]}"
do
  archive="stack-v${version}-${target}.tar.gz"
  provenance="stack-v${version}-${target}.provenance.sigstore.json"
  sbom_attestation="stack-v${version}-${target}.sbom.sigstore.json"

  gh release download "${tag}" --repo "${repository}" --dir "${temporary_directory}" \
    --pattern "${archive}" \
    --pattern "${provenance}" \
    --pattern "${sbom_attestation}"

  manifest_digest="$(ruby -rjson -e '
    manifest = JSON.parse(File.read(ARGV.fetch(0)))
    target = manifest.fetch("targets").find { |entry| entry["target"] == ARGV.fetch(1) }
    abort "target is missing from manifest" unless target
    puts target.dig("archive", "sha256")
  ' "${temporary_directory}/${manifest_name}" "${target}")"

  checksum_digest="$(ruby -e '
    rows = File.readlines(ARGV.fetch(0), chomp: true).map do |line|
      match = line.match(/\A([0-9a-f]{64})  (\S+)\z/)
      match&.captures
    end.compact
    matches = rows.select { |(_, name)| name == ARGV.fetch(1) }
    abort "checksum entry must appear exactly once" unless matches.length == 1
    puts matches.first.first
  ' "${temporary_directory}/${checksums_name}" "${archive}")"

  if command -v shasum >/dev/null 2>&1
  then
    actual_digest="$(shasum -a 256 "${temporary_directory}/${archive}" | awk '{print $1}')"
  else
    actual_digest="$(sha256sum "${temporary_directory}/${archive}" | awk '{print $1}')"
  fi

  if [[ ! "${actual_digest}" =~ ^[0-9a-f]{64}$ || "${actual_digest}" != "${manifest_digest}" || "${actual_digest}" != "${checksum_digest}" ]]
  then
    echo "${archive} digest does not match the release inventory" >&2
    exit 1
  fi

  gh attestation verify "${temporary_directory}/${archive}" \
    --repo "${repository}" \
    --bundle "${temporary_directory}/${provenance}" \
    --signer-workflow "${workflow}" \
    --source-ref "${source_ref}" \
    --deny-self-hosted-runners >/dev/null

  gh attestation verify "${temporary_directory}/${archive}" \
    --repo "${repository}" \
    --bundle "${temporary_directory}/${sbom_attestation}" \
    --predicate-type https://spdx.dev/Document/v2.3 \
    --signer-workflow "${workflow}" \
    --source-ref "${source_ref}" \
    --deny-self-hosted-runners >/dev/null

  digests+=("${actual_digest}")
done

generated_metadata="${temporary_directory}/stack-release.json"
ruby -rjson -e '
  metadata = {
    "schemaVersion" => 1,
    "repository" => "stack-sh/cli",
    "version" => ARGV.fetch(0),
    "sourceCommit" => ARGV.fetch(1),
    "targets" => {
      "aarch64-apple-darwin" => ARGV.fetch(2),
      "aarch64-unknown-linux-gnu" => ARGV.fetch(4),
      "x86_64-apple-darwin" => ARGV.fetch(3),
      "x86_64-unknown-linux-gnu" => ARGV.fetch(5),
    },
  }
  puts JSON.pretty_generate(metadata)
' "${version}" "${source_commit}" "${digests[0]}" "${digests[1]}" "${digests[2]}" "${digests[3]}" >"${generated_metadata}"

generated_formula="${temporary_directory}/stack.rb"
ruby "${root_directory}/scripts/render-stack-formula.rb" "${generated_metadata}" >"${generated_formula}"
ruby -c "${generated_formula}" >/dev/null

if cmp -s "${generated_formula}" "${root_directory}/Formula/stack.rb" &&
   cmp -s "${generated_metadata}" "${root_directory}/metadata/stack-release.json"
then
  echo "Formula/stack.rb already matches Stack CLI ${version}"
  exit 0
fi

chmod 0644 "${generated_formula}"
chmod 0644 "${generated_metadata}"
mv "${generated_metadata}" "${root_directory}/metadata/stack-release.json"
mv "${generated_formula}" "${root_directory}/Formula/stack.rb"
echo "Updated Formula/stack.rb and metadata/stack-release.json to Stack CLI ${version}"
