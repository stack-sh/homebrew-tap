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
      url "https://github.com/stack-sh/cli/releases/download/v0.5.3/stack-v0.5.3-aarch64-apple-darwin.tar.gz"
      sha256 "3502a475cffeff6d16a5429c82948f34577f876211d6d8d94bb1b1de25ea4ce0"
    end

    # Let Homebrew load the formula before reporting the ARM64 requirement.
    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.3/stack-v0.5.3-x86_64-apple-darwin.tar.gz"
      sha256 "321de2f7db93816ea21054e8ea4e0614966fafcd4326145093cc57ddabda2e0c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.3/stack-v0.5.3-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "3803c267db88d6ddaa7d828ff7e59238ec8e69877e698693c7591e3d3a1abfab"
    end

    on_intel do
      url "https://github.com/stack-sh/cli/releases/download/v0.5.3/stack-v0.5.3-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "3f13f497aaa17fbb45249de431cfde29906c6f6f75e1c5d59ec0b3f49f76c6de"
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
