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
      url "https://github.com/stack-sh/cli/releases/download/v0.5.2/stack-v0.5.2-aarch64-apple-darwin.tar.gz"
      sha256 "3290449b4897da9c6433ad9cf1679df5fd7af33a9e1cfe7b16e26718cabd5fd5"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.2/stack-v0.5.2-x86_64-apple-darwin.tar.gz"
      sha256 "08944c2009c885ce7c26d75c8ea62a4a373f2d46ed0ab16f0be63e65c1bf5d2c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.2/stack-v0.5.2-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "6be14c2105d49d1c38382d63deae7bc6ce3268cacd33fe5e44a53117627659b0"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.2/stack-v0.5.2-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "08eee2c7e31e9ec4620bd7315c2c7aea95a64ea49c50c1422486d0c8340ff383"
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
