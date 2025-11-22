class Bulkinstall < Formula
  desc "Bulk Install Script - Simplify bulk package installation across Linux distributions with customizable install commands and package lists"
  homepage "https://github.com/thesmal/homebrew-thesmalrepo"
  url "https://github.com/thesmal/homebrew-thesmalrepo/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "d748fa9bd999c93ecfed42e30241adaeda02086fcb1bb8eb8d9fb99b03972992"
  license "MIT"

  def install
    bin.install "bulkinstall.sh" => "bulkinstall"
    chmod 0755, bin/"bulkinstall"
  end

  test do
    system "#{bin}/bulkinstall", "--help"
  end
end
