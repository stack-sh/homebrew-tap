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
      url "https://github.com/stack-sh/cli/releases/download/v0.5.0/stack-v0.5.0-aarch64-apple-darwin.tar.gz"
      sha256 "cfa5e6459481dec73c0aca5b32d52293c977a4f5d72273f8ea9ce71c4f689ea2"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.0/stack-v0.5.0-x86_64-apple-darwin.tar.gz"
      sha256 "d38e017c93a41855319fd583c4f0d6e62dc688b10ebeedbe925d07ba6dbb7e2b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.0/stack-v0.5.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "506a03d1b430497539bfc2c57ff4a97962a983d1343c983700bc85719e5740cb"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.0/stack-v0.5.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "b159e58c899f77798196616dd1a33fc6a04026cdc582861ee8ac257211abdb9d"
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
