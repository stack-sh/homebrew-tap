#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]
then
  echo "usage: scripts/test-formula-lifecycle.sh TAP_NAME" >&2
  exit 2
fi

tap_name="$1"
formula="${tap_name}/stack"
formula_file="$(brew --repository "${tap_name}")/Formula/stack.rb"
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
[[ "${installed_version}" == "stack 0.3.0" ]]

cp "${formula_file}" "${formula_backup}"
# The Ruby expression must remain literal shell input.
# shellcheck disable=SC2016
ruby -0pi -e '$_.sub!(%{  license "Apache-2.0"\n}, %{  license "Apache-2.0"\n  revision 1\n})' "${formula_file}"
brew upgrade "${formula}"
brew list --versions stack | grep -F '0.3.0_1' >/dev/null
upgraded_version="$("${brew_prefix}/bin/stack" --version)"
[[ "${upgraded_version}" == "stack 0.3.0" ]]

brew uninstall "${formula}"
[[ ! -e "${brew_prefix}/bin/stack" ]]
config_after="$(shasum -a 256 "${XDG_CONFIG_HOME}/stack/config.yaml" | awk '{print $1}')"
icon_after="$(shasum -a 256 "${XDG_CONFIG_HOME}/stack/icons/test-provider/marker.txt" | awk '{print $1}')"
[[ "${config_after}" == "${config_before}" ]]
[[ "${icon_after}" == "${icon_before}" ]]
