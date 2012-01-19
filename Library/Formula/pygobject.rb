require 'formula'

class Pygobject <Formula
  url 'http://ftp.gnome.org/pub/GNOME/sources/pygobject/2.26/pygobject-2.26.0.tar.bz2'
  homepage 'http://pygtk.org'
  sha256 '5554acff9c27b647144143b0459359864e4a6f2ff62c7ba21cf310ad755cf7c7'

  depends_on 'pkg-config' => :build
  depends_on 'glib'
  depends_on 'pycairo'

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-introspection"
    system "make install"
  end
end
