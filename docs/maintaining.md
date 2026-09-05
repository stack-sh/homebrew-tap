# Maintaining the Stack formula

`Formula/stack.rb` maps supported Homebrew hosts to immutable archives from a stable Stack CLI GitHub Release. The tap must not rebuild, re-sign, or repackage those archives.

## Update procedure

1. Wait for the complete Stack CLI release workflow to publish a non-draft, non-prerelease `vMAJOR.MINOR.PATCH` release. Do not use a mutable branch build or a partial draft.
2. Create a short-lived branch from the latest `origin/main` in this repository.
3. Authenticate GitHub CLI for read access to public attestations, then run:

   ```sh
   scripts/update-stack-formula.sh MAJOR.MINOR.PATCH
   ```

   The updater downloads the release manifest, checksum inventory, all four CLI archives, and their provenance and SBOM bundles. Three archives are installable on supported Homebrew hosts; the Intel macOS archive lets Homebrew load the formula before reporting the ARM64 requirement. The updater rejects draft or prerelease versions, manifest drift, missing or duplicate checksum entries, digest mismatch, an unexpected signer workflow or source ref, and self-hosted build provenance. It writes `metadata/stack-release.json` and the generated formula only after all checks pass. The lifecycle matrix then proves the archived bash, zsh, and fish completion files and `stack.1` are installed through Homebrew's managed paths and exactly match the binary generators.
4. Review the generated formula and run the source test:

   ```sh
   scripts/test-formula-source.sh
   git diff --check
   ```

5. Open a pull request. Merge only after the `baseline` gate and every supported host lifecycle job pass.
6. On a clean supported host, run `brew update`, `brew upgrade stack-sh/tap/stack`, `stack --version`, and one `stack render` before announcing the channel.

The update pull request is the synchronization boundary between the CLI release and this tap. No cross-repository write token or long-lived signing credential is required.

## Recovery

- If verification or CI fails, leave the current formula on the last known-good version. Do not weaken a digest, identity, source-ref, architecture, or lifecycle check.
- If the upstream release is incomplete or faulty, fix the CLI and publish a new patch release. Do not replace an existing tag or release asset.
- If a bad formula reaches `main`, submit a pull request that restores the last known-good version and hashes. Do not rewrite public tap history.
- If only formula metadata changes without a new upstream version, add a Homebrew `revision` and exercise the same install/upgrade/uninstall matrix.
- Users can recover from a local stale tap with `brew update-reset stack-sh/tap`, then reinstall the known-good formula. Configuration and imported icon data remain outside the Cellar and must not be deleted by recovery steps.
