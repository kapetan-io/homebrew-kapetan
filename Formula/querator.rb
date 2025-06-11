class Querator < Formula
  desc "An Almost Exactly Once Delivery Queue"
  homepage "https://github.com/kapetan-io/querator"
  url "https://github.com/kapetan-io/querator/archive/v0.0.4.tar.gz"
  sha256 "a4d5884b67243a709cbd7726f7ccad89e850ba013fa52fc21f28389c00ad1b98"
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
