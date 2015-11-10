class ZeroInstall < Formula
  desc "Zero Install is a decentralised software installation system"
  homepage "http://0install.net/"
  url "https://downloads.sf.net/project/zero-install/0install/2.10/0install-2.10.tar.bz2"
  sha256 "44ea5789f5b3b1ce621a4ac446dcb418497266c766d70068c2c723159f0112aa"

  bottle do
    cellar :any
    sha256 "3ab466845d13b43ea73eace0f6c56536f224303f056962f57c35709bf5204385" => :yosemite
    sha256 "ebd5dc48e1bd1d6acaa97fa628fcb16facf0ed24b3a907a657b6087cb7c267cf" => :mavericks
    sha256 "6eca41e9ec6f3fb6e575a34838dca9c87b28bc756f9aa3992bc0da508d47dd55" => :mountain_lion
  end

  depends_on "pkg-config" => :build
  depends_on "ocaml" => :build
  depends_on "opam" => :build
  depends_on "gtk+" => :optional
  depends_on :gpg

  # 0install.2.10 resources from https://github.com/ocaml/opam-repository.git

  resource "easy-format" do # [required by yojson]
    url "https://opam.ocaml.org/archives/easy-format.1.0.2+opam.tar.gz"
    version "1.0.2"
    sha256 "c2a04ab1084bc5ce1ec52a3aa320c825c22f8be527fb5f82d920a9d92a673cd3"
  end

  resource "biniou" do # [required by yojson]
    url "https://opam.ocaml.org/archives/biniou.1.0.9+opam.tar.gz"
    version "1.0.9"
    sha256 "08e6a17a19fbe5e9da4c77d1e8c1bb05333f84ec8a634721a39c6c505ce51e0d"
  end

  resource "cppo" do # [required by yojson]
    url "https://opam.ocaml.org/archives/cppo.1.3.1+opam.tar.gz"
    version "1.3.1"
    sha256 "d4bcbbedab486a187b34976d85af949a9c2d15c3585dff907f5ce3a3c357fefd"
  end

  resource "yojson" do
    url "https://opam.ocaml.org/archives/yojson.1.2.3+opam.tar.gz"
    version "1.2.3"
    sha256 "031a4f5c4c42fd6a454ec6d470ec5d5ab0c119f87b43143e48d921b5a53c24d9"
  end

  resource "xmlm" do
    url "https://opam.ocaml.org/archives/xmlm.1.2.0+opam.tar.gz"
    version "1.2.0"
    sha256 "518617e737730c89a04ca68ae927cb1510a027a9924df591df8575e386d810f0"
  end

  resource "ounit" do
    url "https://opam.ocaml.org/archives/ounit.2.0.0+opam.tar.gz"
    version "2.0.0"
    sha256 "bc87d648a6186d7a708442a9dcb2197e9f0d5d8ba62f60daf18ae8b592b658ce"
  end

  resource "react" do
    url "https://opam.ocaml.org/archives/react.1.2.0+opam.tar.gz"
    version "1.2.0"
    sha256 "690a1a7b18be21fa83876599639ddd3954c2a53d5cf1e13a76f2a140e1f9aa71"
  end

  resource "ppx_tools" do # [required by lwt]
    url "https://opam.ocaml.org/archives/ppx_tools.0.99.3+opam.tar.gz"
    version "0.99.3"
    sha256 "cfbd806cedf756029e61c1b3e622da956704d7107b4dd0a031cfc54ea9e3f84c"
  end

  resource "lwt" do
    url "https://opam.ocaml.org/archives/lwt.2.5.0+opam.tar.gz"
    version "2.5.0"
    sha256 "cb0500a3c2d2eac236748c14aaff6bba4f2c038cd0ff4dadacb53119ccc95b55"
  end

  resource "extlib" do
    url "https://opam.ocaml.org/archives/extlib.1.7.0+opam.tar.gz"
    version "1.7.0"
    sha256 "275bf2b27f5e7c20e8ee2cda4286c70a5acd3af2b8ec487fb9ab5e523c99eda5"
  end

  resource "ocurl" do
    url "https://opam.ocaml.org/archives/ocurl.0.7.5+opam.tar.gz"
    version "0.7.5"
    sha256 "531265e38d67c4eeb2272ccb00a3e2eff951046b809ca61a25c11e874ef9504c"
  end

  if build.with? "gtk+"
    resource "lablgtk" do
      url "https://opam.ocaml.org/archives/lablgtk.2.18.3+opam.tar.gz"
      version "2.18.3"
      sha256 "f0b7ed0bd85f6cf4b4c5f81966f03763e76bb9f866f5172511ce48cf31fd433c"
    end
  end

  resource "sha" do
    url "https://opam.ocaml.org/archives/sha.1.9+opam.tar.gz"
    version "1.9"
    sha256 "d3cfda4cd6f79b01c6613219baa3e8548365c309952168b3539e0edce9370b40"
  end

  def install
    opamroot = buildpath/"opamroot"
    ENV["OPAMROOT"] = opamroot
    ENV["OPAMYES"] = "1"
    system "opam", "init", "--no-setup"
    archives = opamroot/"repo/default/archives"
    modules = []
    resources.each do |r|
      r.verify_download_integrity(r.fetch)
      original_name = File.basename(r.url)
      cp r.cached_download, archives/original_name
      modules << "#{r.name}=#{r.version}"
    end
    system "opam", "install", *modules

    system "opam", "config", "exec", "make"
    inreplace "dist/install.sh", '"/usr/local"', prefix
    inreplace "dist/install.sh", '"${PREFIX}/man"', man
    system "make", "install"
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
    assert_equal "hello world\n", shell_output("#{bin}/0launch --console hello.xml")
  end
end
