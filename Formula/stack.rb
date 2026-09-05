class Stack < Formula
  desc "Language and toolchain for architecture diagrams"
  homepage "https://stack-diagram.com/"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    depends_on arch: :arm64

    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.3.0/stack-v0.3.0-aarch64-apple-darwin.tar.gz"
      sha256 "10df35058c9e8438b331b69392f6b9840cbae3a5278105b0118c3942f62fc356"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.3.0/stack-v0.3.0-x86_64-apple-darwin.tar.gz"
      sha256 "23d8eea13ff2663e059b7ec91cbc8d6bca8825380766e87f1718c2dea217a49f"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.3.0/stack-v0.3.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "2bed2ba5ff4a727646cedb4ec77ac875e09fc3ede996a963022d9a97ccdbf7ac"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.3.0/stack-v0.3.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "6c9ab21d96fc6fb0a12a6ff4f7f56103d8dd8513ac85c8d30ab6e072c5c6a7d9"
    end
  end

  def install
    bin.install "stack"
    doc.install "LICENSE", "NOTICE", "THIRD_PARTY_LICENSES.md"
  end

  test do
    assert_equal "stack #{version}", shell_output("#{bin}/stack --version").strip

    system bin/"stack", "init", "--template", "hello-stack", "-o", testpath/"diagram.stack"
    system bin/"stack", "check", testpath/"diagram.stack"
    system bin/"stack", "render", testpath/"diagram.stack", "-o", testpath/"diagram.svg"

    assert_path_exists testpath/"diagram.svg"
    assert_match "<svg", (testpath/"diagram.svg").read
  end
end
