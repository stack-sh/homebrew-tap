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
      url "https://github.com/stack-sh/cli/releases/download/v0.5.4/stack-v0.5.4-aarch64-apple-darwin.tar.gz"
      sha256 "91eb7913c13406a1734c57ad756f141353160cfde653b871cdb468bf47a3e6fe"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.4/stack-v0.5.4-x86_64-apple-darwin.tar.gz"
      sha256 "f2ba7cc56e5ffe3e327fc26ddc7bc72f6803417dbaff54a6ab050f89cb2cbf6a"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.4/stack-v0.5.4-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "3caa9e0db3770a929afb88c718a3e576cce1d4b7190c48f7b3762eebdcac13a1"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.4/stack-v0.5.4-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "56e7fee5cbb11072fcba03e75f5c5e7fad669a65625381e988eb05c4ec0b1a9f"
    end
  end

  def install
    bin.install "stack"
    bash_completion.install "share/bash-completion/completions/stack"
    zsh_completion.install "share/zsh/site-functions/_stack"
    fish_completion.install "share/fish/vendor_completions.d/stack.fish"
    man1.install "share/man/man1/stack.1"
    doc.install "LICENSE", "NOTICE", "THIRD_PARTY_LICENSES.md"
  end

  test do
    assert_equal "stack #{version}", shell_output("#{bin}/stack --version").strip

    system bin/"stack", "init", "--template", "hello-stack", "-o", testpath/"diagram.stack"
    system bin/"stack", "check", testpath/"diagram.stack"
    system bin/"stack", "render", testpath/"diagram.stack", "-o", testpath/"diagram.svg"

    assert_path_exists testpath/"diagram.svg"
    assert_match "<svg", (testpath/"diagram.svg").read
    assert_equal shell_output("#{bin}/stack completions bash"), (bash_completion/"stack").read
    assert_equal shell_output("#{bin}/stack completions zsh"), (zsh_completion/"_stack").read
    assert_equal shell_output("#{bin}/stack completions fish"), (fish_completion/"stack.fish").read
    assert_equal shell_output("#{bin}/stack manpage"), (man1/"stack.1").read
    assert_match ".TH STACK 1", (man1/"stack.1").read
  end
end
