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
      url "https://github.com/stack-sh/cli/releases/download/v0.4.0/stack-v0.4.0-aarch64-apple-darwin.tar.gz"
      sha256 "dd43cf3d966a3dc28de3ac8752b6a98f19e4cb7cf6b04652ab73a013800cb015"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.4.0/stack-v0.4.0-x86_64-apple-darwin.tar.gz"
      sha256 "48a72328fcf6d160a123a766d9701108f8ee9f633001581dab533b93dddf0827"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.4.0/stack-v0.4.0-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "a0d76bfa9ed9e767fcd06dbeb7140234db865440210c7c3abf6c3db4f6983a6e"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.4.0/stack-v0.4.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "89d8a34c0da5f67932edff2641fe0a0527afbd120cfd5133cb38cdeffca55319"
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
