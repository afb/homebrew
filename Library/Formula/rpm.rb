require 'formula'

class RpmDownloadStrategy < CurlDownloadStrategy
  attr_reader :tarball_name
  def initialize url, name, version, specs
    super
    @tarball_name="#{name}-#{version}.tar.gz"
  end
  def stage
    safe_system "rpm2cpio <#{@tarball_path} | cpio -vi #{@tarball_name}"
    safe_system "tar -xzf #{@tarball_name} && rm #{@tarball_name}"
    chdir
  end
end

class Rpm < Formula
  homepage 'http://www.rpm5.org/'
  url 'http://rpm5.org/files/rpm/rpm-5.4/rpm-5.4.9-0.20120508.src.rpm',
      :using => RpmDownloadStrategy
  version '5.4.9'
  md5 '60d56ace884340c1b3fcac6a1d58e768'

  depends_on 'db'
  depends_on 'libmagic'
  depends_on 'popt'
  depends_on 'beecrypt'
  depends_on 'neon'
  depends_on 'gettext'
  depends_on 'xz'
  depends_on 'ossp-uuid'
  depends_on 'pcre'
  depends_on 'rpm2cpio'
  depends_on 'libtool'

  fails_with :clang do
    build 318
  end

  def install
    args = %W[
        --prefix=#{prefix}
        --with-path-cfg=#{etc}/rpm
        --disable-openmp
        --disable-nls
        --disable-dependency-tracking
        --without-apidocs
    ]

    system 'glibtoolize -if' # needs updated ltmain.sh
    system "./configure", *args
    system "make"
    system "make install"

    # conflicts with rpm2cpio package - which is required for downloading
    system "/bin/rm", "-f", "#{bin}/rpm2cpio"
  end
end
