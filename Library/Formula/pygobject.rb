require 'formula'

class Pygobject <Formula
  url 'http://ftp.gnome.org/pub/GNOME/sources/pygobject/2.28/pygobject-2.28.0.tar.bz2'
  homepage 'http://pygtk.org'
  sha256 '12b3c6516c803e3cada4585bd45456897c8e02a7b390dfd05683b93c50ec66ba'

  depends_on 'pkg-config' => :build
  depends_on 'glib'
  depends_on 'pycairo'

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-introspection"
    system "make install"
  end
end
