class Bulkinstall < Formula
  desc "Bulk Install Script - Simplify bulk package installation across Linux distributions with customizable install commands and package lists"
  homepage "https://github.com/thesmal/homebrew-thesmalrepo"
  url "https://github.com/thesmal/homebrew-thesmalrepo/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b"  # Replace with actual SHA256 checksum
  license "MIT"

  def install
    bin.install "bulkinstall.sh" => "bulkinstall"
    chmod 0755, bin/"bulkinstall"
  end

  test do
    system "#{bin}/bulkinstall", "--help"
  end
end
