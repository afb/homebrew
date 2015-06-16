class Wxgtk < Formula
  desc "wxWidgets, a cross-platform C++ GUI toolkit (for GTK+)"
  homepage "http://www.wxwidgets.org/"
  url "https://downloads.sourceforge.net/project/wxwindows/files/2.8.12/wxGTK-2.8.12.tar.gz"
  sha256 "13cf89f2c29bcb90bb56a31ac1af10f23003d3d43c3e4b24991518f5dc4e5abe"

  depends_on :x11
  depends_on "gtk+"

  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"

  def install
    system "./configure", "--with-x",
                          "--x-includes=#{MacOS::X11.include}",
                          "--x-libraries=#{MacOS::X11.lib}",
                          "--with-gtk",
                          "--with-opengl",
                          "--with-libjpeg",
                          "--with-libpng",
                          "--with-libtiff",
                          "--enable-shared",
                          "--enable-unicode",
                          "--disable-precomp-headers",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "LIBS=-lX11 -lGL", "install"
  end

  test do
    system "wx-config", "--libs"
  end
end
