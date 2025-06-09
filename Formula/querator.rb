class Querator < Formula
  desc "Distributed Durable Execution System built on an Almost Exactly Once Delivery Queue"
  homepage "https://github.com/kapetan-io/querator"
  url "https://github.com/kapetan-io/querator/archive/v0.0.1.tar.gz"
  sha256 "74f3874b060d980ed48139aba9754c8fb777d6be726592c8413ab7c1271a16ae"
  license "Apache-2.0"
  head "https://github.com/kapetan-io/querator.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}"), "./cmd/querator"
  end

  test do
    # Test that the binary was installed and can show version
    assert_match version.to_s, shell_output("#{bin}/querator --version")
  end
end