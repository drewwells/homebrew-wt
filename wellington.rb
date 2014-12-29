require "formula"
require "language/go"

class Wellington < Formula
  homepage "https://github.com/wellington/wellington"
  url "https://github.com/wellington/wellington/archive/v0.6.0-alpha1.tar.gz"
  sha1 "52a5cca3025f922a8f03f92ef947c848160f17ae"
  head "https://github.com/wellington/wellington.git"

  needs :cxx11

  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  go_resource "github.com/wellington/spritewell" do
    url "https://github.com/wellington/spritewell.git",
        :revision => "748bfe956f31c257605c304b41a0525a4487d17d"
  end

  go_resource "github.com/go-fsnotify/fsnotify" do
    url "https://github.com/go-fsnotify/fsnotify.git",
        :revision => "f582d920d11386e8ae15227bb5933a8f9b4c3dec"
  end

  # The revision must match .libsass_version in the project.
  # https://github.com/wellington/wellington/blob/master/.libsass_version
  resource "github.com/sass/libsass" do
    url "https://github.com/sass/libsass.git",
        :revision => "3b0feb9f13d5885de9f2ceec81b9a66a76f9be2d"
  end

  def install
    ENV.cxx11
    resource("github.com/sass/libsass").stage {
      ENV["LIBSASS_VERSION"]="3b0feb9f13d5885de9f2ceec81b9a66a76f9be2d"
      system "autoreconf", "--force", "--install"
      system "./configure",
             "--disable-tests",
             "--disable-shared",
             "--prefix=#{buildpath}/libsass",
             "--disable-silent-rules",
             "--disable-dependency-tracking"
      system "make", "install"
    }
    # go_resource doesn't support gopkg, do it manually then symlink
    mkdir_p buildpath/"src/gopkg.in"
    ln_s buildpath/"src/github.com/go-fsnotify/fsnotify", buildpath/"src/gopkg.in/fsnotify.v1"
    ENV.append_path "PKG_CONFIG_PATH", buildpath/"libsass/lib/pkgconfig"
    mkdir_p buildpath/"src/github.com/wellington"
    ln_s buildpath, buildpath/"src/github.com/wellington/wellington"
    Language::Go.stage_deps resources, buildpath/"src"
    ENV["GOPATH"] = buildpath
    ENV.append 'CGO_LDFLAGS', '-stdlib=libc++' if ENV.compiler == :clang
    system "go", "build", "-x", "-v", "-o", "dist/wt", "wt/main.go"

    bin.install "dist/wt"
  end

  test do
    s = 'div { p { color: red; } }'
    expected = <<-EOS.undent
      div p {
        color: red; }
    EOS
    output = `echo '#{s}' | #{bin}/wt`
    assert_equal(expected, output)
  end
end
