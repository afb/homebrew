class SubversionRevisionDownloadStrategy < SubversionDownloadStrategy
  def fetch
    super
    # Update revision.m4 after fetching from svn
    cd cached_location
    safe_system "./update_revision.sh"
  end

  def stage
    super
    cp "#{cached_location}/revision.m4", Dir.pwd
  end
end

class Codeblocks < Formula
  desc "C, C++ and Fortran IDE"
  homepage "http://www.codeblocks.org/"
  url "https://downloads.sourceforge.net/project/codeblocks/Sources/13.12/codeblocks_13.12-1.tar.gz"
  version "13.12"
  sha256 "772450046e8c8ba2ea0086acf433a46b83e6254fae64df9c8ca132a22f949610"

  head do
    url "svn://svn.code.sf.net/p/codeblocks/code/trunk", :using => SubversionRevisionDownloadStrategy
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option "with-contrib-plugins", "Build with contrib plugins"

  depends_on :x11
  depends_on "wxgtk"

  if build.with? "contrib-plugins"
    depends_on "hunspell" # for the SpellChecker plugin
    depends_on "gtk+" # for the MouseSap plugin
    depends_on "fontconfig" # for the exporter plugin
    depends_on "boost" => :build # for the NassiShneiderman plugin
  end

  # https://github.com/jenslody/codeblocks/commit/8455425c3a300beaaff93118a7db29312878fd76
  patch :DATA unless build.head?

  def install
    system "./bootstrap" if build.head?
    inreplace "configure", "-Wl,--no-undefined", "-Wl,-undefined,error"
    # for some reason pluginmanager tries to use *.dylib for plugins (it should be *.so for bundles)
    inreplace "src/sdk/pluginmanager.cpp", "platform::darwin || platform::macosx", "platform::macosx"
    args = %W[
      --with-x
      --x-includes=#{MacOS::X11.include}
      --x-libraries=#{MacOS::X11.lib}
      --with-platform=gtk
      --disable-pch
      --disable-dependency-tracking
      --prefix=#{prefix}
    ]
    if build.with? "contrib-plugins"
      args << "--with-contrib-plugins=all,-FileManager" # the FileManager plugin requires GAMIN
    else
      args << "--with-contrib-plugins=none"
    end
    system "./configure", *args
    system "make", "install"
  end

  test do
    system "codeblocks"
  end
end

__END__
diff --git a/src/sdk/wxscintilla/src/scintilla/src/CallTip.h b/src/sdk/wxscintilla/src/scintilla/src/CallTip.h
index 840aa26..4cc7f3d 100644
--- a/src/sdk/wxscintilla/src/scintilla/src/CallTip.h
+++ b/src/sdk/wxscintilla/src/scintilla/src/CallTip.h
@@ -12,6 +12,10 @@
 namespace Scintilla {
 #endif
 
+/* C::B begin */
+#include <string>
+/* C::B end */
+
 /**
  */
 class CallTip {
