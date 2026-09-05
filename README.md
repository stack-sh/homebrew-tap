# Stack Homebrew Tap

This is the official Homebrew tap for the [Stack CLI](https://github.com/stack-sh/cli).

## Install

Install and trust only the Stack formula:

```sh
brew install stack-sh/tap/stack
stack --version
```

The formula installs the exact archives published by the Stack CLI GitHub Release. It does not rebuild or repackage the binary.

| Host | Homebrew support | Stack release target |
| --- | --- | --- |
| Apple Silicon macOS on a current Homebrew Tier 1 release | Supported | `aarch64-apple-darwin` |
| ARM64 Linux on a current Homebrew Tier 1 host | Supported | `aarch64-unknown-linux-gnu` |
| x86_64 Linux with SSSE3 on a current Homebrew Tier 1 host | Supported | `x86_64-unknown-linux-gnu` |
| Intel macOS | Unsupported by this formula | — |

Stack CLI 0.3.0 does not publish shell completion files. Completion generation and package integration will be added in a future CLI release instead of being duplicated in this tap.

## Upgrade and uninstall

```sh
brew update
brew upgrade stack-sh/tap/stack
```

Homebrew owns upgrades for this installation. Do not replace the installed binary with a direct-download or self-update command.

```sh
brew uninstall stack-sh/tap/stack
```

Upgrade and uninstall only change files managed in the Homebrew Cellar. Stack configuration and imported provider icons under `$XDG_CONFIG_HOME/stack`, or `$HOME/.config/stack` when `XDG_CONFIG_HOME` is unset, are intentionally preserved.

## Verification and maintenance

The formula test runs `stack --version`, `init`, `check`, and `render`. CI additionally verifies the three supported host mappings, formula syntax and style, upstream GitHub attestations, upgrade behavior, uninstall behavior, and preservation of configuration and icon data.

See [Maintaining the formula](./docs/maintaining.md) for the fail-closed update and recovery procedure. Security reports should follow [SECURITY.md](./SECURITY.md).
