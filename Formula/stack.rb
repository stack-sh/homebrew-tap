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
      url "https://github.com/stack-sh/cli/releases/download/v0.5.1/stack-v0.5.1-aarch64-apple-darwin.tar.gz"
      sha256 "00572032c4dcf54602e41c23ffeb2fa189709d16a8939fe3549de335f2de811e"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.1/stack-v0.5.1-x86_64-apple-darwin.tar.gz"
      sha256 "d60f57a7a8f4fd1280fdd3b7c0871e9dbb53df23f4a5a168d843e469c9a05984"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.1/stack-v0.5.1-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "4fa61751a4bdd7d066255751549459b6303cfced9243f78a2baa41844719c0cf"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.1/stack-v0.5.1-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "a551f526501ac051457ac354f67d56a14817d59b7db37da103df30da4e7c96a9"
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
