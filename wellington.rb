require "formula"
require "language/go"

class Wellington < Formula
  homepage "https://github.com/wellington/wellington"
  url "https://github.com/wellington/wellington/archive/e892483423eceb3196c02b9671cb6a36dd364aab.tar.gz"
  #sha1 "c3abd876e209c00a7563866e07028db359a8d4f6"
  head "https://github.com/wellington/wellington.git"

  needs :cxx11

  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  go_resource "github.com/wellington/spritewell" do
    url "https://github.com/wellington/spritewell.git",
        :revision => "3a43f26d94a6da8e40884d1edca0ff372ab7487d"
    sha1 ""
  end

  go_resource "github.com/go-fsnotify/fsnotify" do
    url "https://github.com/go-fsnotify/fsnotify.git",
        :revision => "f582d920d11386e8ae15227bb5933a8f9b4c3dec"
    sha1 "2bd8459d120337ad68cb119b6761130c2e07d053"
  end

  resource "github.com/sass/libsass" do
    url "https://github.com/sass/libsass.git"
    sha1 "705e6dc406229571ee992e83b797fb4abbecb826"
  end

  def install
    resource("github.com/sass/libsass").stage {
      ENV["LIBSASS_VERSION"]="705e6d"
      system "autoreconf", "-fvi"
      system "./configure", "--prefix=#{buildpath}/libsass",
             "--enable-static",
             "--disable-silent-rules",
             "--disable-dependency-tracking"
      system "make", "install"
      # dylibs will be used if found, remove them to force static binding
      rm Dir.glob("#{buildpath}/libsass/lib/*dylib")
    }
    # go_resource doesn't support gopkg, do it manually then symlink
    mkdir_p buildpath/"src/gopkg.in"
    ln_s buildpath/"src/github.com/go-fsnotify/fsnotify", buildpath/"src/gopkg.in/fsnotify.v1"
    ENV.append_path "PKG_CONFIG_PATH", buildpath/"libsass/lib/pkgconfig"
    mkdir_p buildpath/"src/github.com/wellington"
    ln_s buildpath, buildpath/"src/github.com/wellington/wellington"
    Language::Go.stage_deps resources, buildpath/"src"
    ENV["GOPATH"] = buildpath

    system "go", "build", "-o", "dist/wt", "wt/main.go"
    bin.install "dist/wt"
  end

  test do
    path = testpath/"file.scss"
    path.write "div { p { color: red; }}"
    expected = <<-EOS.undent
      /* line 6, stdin */
      div p {
        color: red; }
    EOS
    output = `#{bin}/wt #{path}`
    assert_equal(expected, output)
  end
end
