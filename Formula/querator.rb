class Querator < Formula
  desc "An Almost Exactly Once Delivery Queue"
  homepage "https://github.com/kapetan-io/querator"
  url "https://github.com/kapetan-io/querator/archive/v0.0.8.tar.gz"
  sha256 "c34ce1e7da057daacb45ccbf784ad42e045af80da6b7b60462fcad2d2c3a7c32"
  license "Apache-2.0"
  head "https://github.com/kapetan-io/querator.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/kapetan-io/querator.Version=#{version}"), "./cmd/querator"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/querator version")
  end
end
