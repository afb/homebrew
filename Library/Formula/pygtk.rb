require 'formula'

class Pygtk <Formula
  url 'http://ftp.gnome.org/pub/GNOME/sources/pygtk/2.24/pygtk-2.24.0.tar.bz2'
  homepage 'http://pygtk.org'
  sha256 'cd1c1ea265bd63ff669e92a2d3c2a88eb26bcd9e5363e0f82c896e649f206912'

  depends_on 'pkg-config' => :build
  depends_on 'gtk+'
  depends_on 'libglade'
  depends_on 'pygobject'
  depends_on 'pycairo'

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make install"
  end

  def caveats
    python_ver = `python -c 'import sys; print sys.version[:3]'`.chomp
    python_lib = "#{HOMEBREW_PREFIX}/lib/python#{python_ver}"
    <<-EOS
This formula won't function until you amend your PYTHONPATH like so:
    export PYTHONPATH=#{python_lib}/site-packages/gtk-2.0:#{python_lib}/site-packages:$PYTHONPATH
EOS
  end

  def test
    python_ver = `python -c 'import sys; print sys.version[:3]'`.chomp
    python_lib = "#{HOMEBREW_PREFIX}/lib/python#{python_ver}"
    ENV.prepend 'PYTHONPATH', "#{python_lib}/site-packages/gtk-2.0:#{python_lib}/site-packages", ':'
    system "pygtk-demo"
  end
end
