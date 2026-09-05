#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]
then
  echo "usage: scripts/test-formula-lifecycle.sh TAP_NAME" >&2
  exit 2
fi

tap_name="$1"
formula="${tap_name}/stack"
tap_repository="$(brew --repository "${tap_name}")"
formula_file="${tap_repository}/Formula/stack.rb"
expected_version="$(ruby -rjson -e 'puts JSON.parse(File.read(ARGV.fetch(0))).fetch("version")' "${tap_repository}/metadata/stack-release.json")"
brew_prefix="$(brew --prefix)"
temporary_directory="$(mktemp -d)"
formula_backup="${temporary_directory}/stack.rb"
export XDG_CONFIG_HOME="${temporary_directory}/config"
export HOMEBREW_NO_AUTO_UPDATE=1

cleanup() {
  if [[ -f "${formula_backup}" ]]
  then
    cp "${formula_backup}" "${formula_file}"
  fi
  brew uninstall --force stack >/dev/null 2>&1 || true
  rm -rf "${temporary_directory}"
}
trap cleanup EXIT

mkdir -p "${XDG_CONFIG_HOME}/stack/icons/test-provider"
printf '%s\n' 'default_icons_path: /tmp/unchanged-by-homebrew' >"${XDG_CONFIG_HOME}/stack/config.yaml"
printf '%s\n' 'icon-store-marker' >"${XDG_CONFIG_HOME}/stack/icons/test-provider/marker.txt"
config_before="$(shasum -a 256 "${XDG_CONFIG_HOME}/stack/config.yaml" | awk '{print $1}')"
icon_before="$(shasum -a 256 "${XDG_CONFIG_HOME}/stack/icons/test-provider/marker.txt" | awk '{print $1}')"

brew uninstall --force stack >/dev/null 2>&1 || true
brew install "${formula}"
brew test "${formula}"
installed_version="$("${brew_prefix}/bin/stack" --version)"
[[ "${installed_version}" == "stack ${expected_version}" ]]
managed_files=(
  "${brew_prefix}/etc/bash_completion.d/stack"
  "${brew_prefix}/share/zsh/site-functions/_stack"
  "${brew_prefix}/share/fish/vendor_completions.d/stack.fish"
  "${brew_prefix}/share/man/man1/stack.1"
)
for managed_file in "${managed_files[@]}"
do
  [[ -s "${managed_file}" ]]
done
"${brew_prefix}/bin/stack" completions bash | cmp "${brew_prefix}/etc/bash_completion.d/stack" -
"${brew_prefix}/bin/stack" completions zsh | cmp "${brew_prefix}/share/zsh/site-functions/_stack" -
"${brew_prefix}/bin/stack" completions fish | cmp "${brew_prefix}/share/fish/vendor_completions.d/stack.fish" -
"${brew_prefix}/bin/stack" manpage | cmp "${brew_prefix}/share/man/man1/stack.1" -

cp "${formula_file}" "${formula_backup}"
# The Ruby expression must remain literal shell input.
# shellcheck disable=SC2016
ruby -0pi -e '$_.sub!(%{  license "Apache-2.0"\n}, %{  license "Apache-2.0"\n  revision 1\n})' "${formula_file}"
brew upgrade "${formula}"
brew list --versions stack | grep -F "${expected_version}_1" >/dev/null
upgraded_version="$("${brew_prefix}/bin/stack" --version)"
[[ "${upgraded_version}" == "stack ${expected_version}" ]]

brew uninstall "${formula}"
[[ ! -e "${brew_prefix}/bin/stack" ]]
for managed_file in "${managed_files[@]}"
do
  [[ ! -e "${managed_file}" ]]
done
config_after="$(shasum -a 256 "${XDG_CONFIG_HOME}/stack/config.yaml" | awk '{print $1}')"
icon_after="$(shasum -a 256 "${XDG_CONFIG_HOME}/stack/icons/test-provider/marker.txt" | awk '{print $1}')"
[[ "${config_after}" == "${config_before}" ]]
[[ "${icon_after}" == "${icon_before}" ]]
