require 'formula'

class RpmDownloadStrategy < CurlDownloadStrategy
  attr_reader :tarball_name
  def initialize name, package
    super
    package_name = @spec == :name ? @ref : name
    @tarball_name="#{package_name}-#{package.version}.tar.gz"
  end
  def stage
    safe_system "rpm2cpio.pl <#{@tarball_path} | cpio -vi #{@tarball_name}"
    safe_system "/usr/bin/tar -xzf #{@tarball_name} && rm #{@tarball_name}"
    chdir
  end

  def ext
    ".src.rpm"
  end
end

class Rpm < Formula
  homepage 'http://www.rpm5.org/'
  url 'http://rpm5.org/files/rpm/rpm-5.4/rpm-5.4.11-0.20130708.src.rpm',
      :using => RpmDownloadStrategy, :name => 'rpm'
  version '5.4.11'
  sha1 'a40328cf49f43d33746c503a390e3955f5bd3680'

  depends_on 'berkeley-db'
  depends_on 'libmagic'
  depends_on 'popt'
  depends_on 'beecrypt'
  depends_on 'libtasn1'
  depends_on 'neon'
  depends_on 'gettext'
  depends_on 'xz'
  depends_on 'ossp-uuid'
  depends_on 'pcre'
  depends_on 'rpm2cpio' => :build

  # nested functions are not std C
  def patches
    DATA
  end

  def install
    args = %W[
        --prefix=#{prefix}
        --localstatedir=#{var}
        --with-path-cfg=#{etc}/rpm
        --disable-openmp
        --disable-nls
        --disable-dependency-tracking
        --with-db=external
        --with-file=external
        --with-popt=external
        --with-beecrypt=external
        --with-libtasn1=external
        --with-neon=external
        --with-uuid=external
        --with-pcre=external
        --with-lua=internal
        --with-syck=internal
        --without-apidocs
        varprefix=#{var}
    ]

    system "./configure", *args
    system "make"
    system "make install"
  end

  def spec
    <<-EOS.undent
      Summary:   Test package
      Name:      test
      Version:   1.0
      Release:   1
      License:   Public Domain
      Group:     Development/Tools
      BuildArch: noarch

      %description
      Trivial test package

      %prep
      %build
      %install

      %files

      %changelog

    EOS
  end

  def rpmdir macro
    return Pathname.new(`#{bin}/rpm --eval #{macro}`.chomp)
  end

  def test
    system "#{bin}/rpm", "--version"
    rpmdir('%_builddir').mkpath
    specfile = rpmdir('%_specdir')+'test.spec'
    specfile.unlink if specfile.exist?
    (specfile).write(spec)
    system "#{bin}/rpmbuild", "-ba", specfile
  end
end

__END__
diff -ur rpm-5.4.8.orig/macros/macros.in rpm-5.4.8/macros/macros.in
--- rpm-5.4.8.orig/macros/macros.in	2012-03-21 19:04:06.000000000 -0500
+++ rpm-5.4.8/macros/macros.in	2012-06-07 17:02:53.903046624 -0500
@@ -985,7 +985,7 @@
 
 #==============================================================================
 # ---- rpmbuild macros.
-#%%{load:%{_usrlibrpm}/macros.rpmbuild}
+%{load:%{_usrlibrpm}/macros.rpmbuild}
 
 #------------------------------------------------------------------------
 # cmake(...) configuration
