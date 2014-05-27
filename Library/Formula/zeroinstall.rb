require "formula"

class GnupgRequirement < Requirement
  def message; <<-EOS.undent
    Gnupg is required to use these tools.

    You can install Gnupg or Gnupg2 with Homebrew:
      brew install gnupg
      brew install gnupg2

    Or you can use one of several different
    prepackaged installers that are available.
    EOS
  end

  def satisfied?
    which 'gpg' or which 'gpg2'
  end

  def fatal?
    false
  end
end

class Zeroinstall < Formula
  homepage "http://0install.net/injector.html"
  url "https://downloads.sf.net/project/zero-install/0install/2.7/0install-2.7.tar.bz2"
  sha1 "6a36acfb32bb178a63b7e28517a727e22f95dd74"

  option 'with-gui', "Build the 0install gui (requires GTK+)"

  depends_on GnupgRequirement
  depends_on "gtk+" if build.with? "gui"
  depends_on "pkg-config" => :build
  depends_on "objective-caml" => :build
  depends_on "opam" => :build

  head do
    url "https://github.com/0install/0install"
    depends_on "gettext" => :build
  end

  def install
    modules = "yojson xmlm ounit react lwt extlib ssl ocurl"
    modules += " lablgtk" if build.with? "gui"

    # Parellel builds fail for some of these opam libs.
    ENV.deparallelize

    # Set up a temp opam dir for building. Since ocaml statically links against ocaml libs, it won't be needed later.
    # TODO: Use $OPAMCURL to store a cache outside the build directory
    ENV["OPAMCURL"] = "curl"
    ENV["OPAMROOT"] = "opamroot"
    ENV["OPAMYES"] = "1"
    ENV["OPAMVERBOSE"] = "1"
    system "opam init --no-setup"
    system "opam install #{modules}"
    system "opam config exec make"
    system "cd dist && ./install.sh #{prefix}"
  end

  test do
    (testpath/"hello.py").write <<-EOS.undent
      print("hello world")
    EOS
    (testpath/"hello.xml").write <<-EOS.undent
      <?xml version="1.0" ?>
      <interface xmlns="http://zero-install.sourceforge.net/2004/injector/interface">
        <name>Hello</name>
        <summary>minimal demonstration program</summary>

        <implementation id="." version="0.1-pre">
          <command name='run' path='hello.py'>
            <runner interface='http://repo.roscidus.com/python/python'></runner>
          </command>
        </implementation>
      </interface>
    EOS
    assert_equal "hello world\n", `#{bin}/0launch --console hello.xml`
  end
end
