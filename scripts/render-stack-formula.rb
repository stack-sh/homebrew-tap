#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

abort "usage: render-stack-formula.rb METADATA" if ARGV.length != 1

metadata = JSON.parse(File.read(ARGV.fetch(0)))
abort "schema version is unsupported" if metadata["schemaVersion"] != 1
abort "repository is unsupported" if metadata["repository"] != "stack-sh/cli"

version = metadata["version"]
abort "version must use major.minor.patch" unless version.match?(/\A\d+\.\d+\.\d+\z/)
abort "source commit is invalid" unless metadata["sourceCommit"]&.match?(/\A[0-9a-f]{40}\z/)

targets = metadata["targets"]
expected_targets = %w[
  aarch64-apple-darwin
  aarch64-unknown-linux-gnu
  x86_64-apple-darwin
  x86_64-unknown-linux-gnu
]
abort "target set is invalid" if !targets.is_a?(Hash) || targets.keys.sort != expected_targets.sort

hashes = {
  "macOS ARM64"  => targets["aarch64-apple-darwin"],
  "macOS x86_64" => targets["x86_64-apple-darwin"],
  "Linux ARM64"  => targets["aarch64-unknown-linux-gnu"],
  "Linux x86_64" => targets["x86_64-unknown-linux-gnu"],
}
hashes.each do |label, digest|
  abort "#{label} SHA-256 is invalid" unless digest&.match?(/\A[0-9a-f]{64}\z/)
end

macos_arm_sha = hashes.fetch("macOS ARM64")
macos_intel_sha = hashes.fetch("macOS x86_64")
linux_arm_sha = hashes.fetch("Linux ARM64")
linux_intel_sha = hashes.fetch("Linux x86_64")

puts <<~FORMULA
  class Stack < Formula
    desc "Language and toolchain for architecture diagrams"
    homepage "https://stack-diagram.com/"
    license "Apache-2.0"

    livecheck do
      url :stable
      regex(/^v?(\\d+(?:\\.\\d+)+)$/i)
    end

    on_macos do
      depends_on arch: :arm64

      on_arm do
        url "https://github.com/stack-sh/cli/releases/download/v#{version}/stack-v#{version}-aarch64-apple-darwin.tar.gz"
        sha256 "#{macos_arm_sha}"
      end

      # Let Homebrew load the formula before reporting the ARM64 requirement.
      on_intel do
        url "https://github.com/stack-sh/cli/releases/download/v#{version}/stack-v#{version}-x86_64-apple-darwin.tar.gz"
        sha256 "#{macos_intel_sha}"
      end
    end

    on_linux do
      on_arm do
        url "https://github.com/stack-sh/cli/releases/download/v#{version}/stack-v#{version}-aarch64-unknown-linux-gnu.tar.gz"
        sha256 "#{linux_arm_sha}"
      end

      on_intel do
        url "https://github.com/stack-sh/cli/releases/download/v#{version}/stack-v#{version}-x86_64-unknown-linux-gnu.tar.gz"
        sha256 "#{linux_intel_sha}"
      end
    end

    def install
      bin.install "stack"
      doc.install "LICENSE", "NOTICE", "THIRD_PARTY_LICENSES.md"
    end

    test do
      assert_equal "stack \#{version}", shell_output("\#{bin}/stack --version").strip

      system bin/"stack", "init", "--template", "hello-stack", "-o", testpath/"diagram.stack"
      system bin/"stack", "check", testpath/"diagram.stack"
      system bin/"stack", "render", testpath/"diagram.stack", "-o", testpath/"diagram.svg"

      assert_path_exists testpath/"diagram.svg"
      assert_match "<svg", (testpath/"diagram.svg").read
    end
  end
FORMULA
