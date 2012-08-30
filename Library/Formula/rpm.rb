require 'formula'

class RpmDownloadStrategy < CurlDownloadStrategy
  def stage
    safe_system "rpm2cpio <#{@tarball_path} | cpio -dvim"
    safe_system "tar -xzf #{@unique_token}*gz"
    chdir
  end

  def ext
    ".src.rpm"
  end
end

class Rpm < Formula
  homepage 'http://www.rpm5.org/'
  url 'http://rpm5.org/files/rpm/rpm-5.4/rpm-5.4.10-0.20120706.src.rpm',
      :using => RpmDownloadStrategy
  version '5.4.10'
  sha1 '20e5cc7e29ff45b6c5378dbe8ae4af4d1b217971'

  depends_on 'db'
  depends_on 'libmagic'
  depends_on 'popt'
  depends_on 'beecrypt'
  depends_on 'neon'
  depends_on 'gettext'
  depends_on 'xz'
  depends_on 'ossp-uuid'
  depends_on 'pcre'
  depends_on 'rpm2cpio' => :build
  depends_on 'libtool' => :build

  # nested functions are not std C
  def patches
    DATA
  end

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

__END__
--- rpm-5.4.10/rpmio/set.c.orig	2012-07-06 17:39:19.000000000 +0200
+++ rpm-5.4.10/rpmio/set.c	2012-07-30 23:36:16.000000000 +0200
@@ -9,10 +9,6 @@
 /* XXX FIXME: avoid <fcntl.h> borkage on RHEL for now. */
 #define _FCNTL_H        1
 
-/* XXX nested functions in GCC --std=c99 spew mucho here if not */
-#pragma GCC diagnostic ignored "-Wmissing-prototypes"
-#pragma GCC diagnostic ignored "-Woverride-init"
-
 #include "system.h"
 
 #include <rpmio.h>
@@ -54,12 +50,8 @@
     return bitc / 5 + 2;
 }
 
-/* Main base62 encoding routine: pack bitv into base62 string. */
-static
-int encode_base62(int bitc, const char *bitv, char *base62)
-{
-    char *base62_start = base62;
-    void put_digit(int c)
+    static
+    void put_digit(char *base62, int c)
     {
 	assert(c >= 0 && c <= 61);
 	if (c < 10)
@@ -69,6 +61,12 @@
 	else if (c < 62)
 	    *base62++ = c - 36 + 'A';
     }
+
+/* Main base62 encoding routine: pack bitv into base62 string. */
+static
+int encode_base62(int bitc, const char *bitv, char *base62)
+{
+    char *base62_start = base62;
     int bits2 = 0; /* number of high bits set */
     int bits6 = 0; /* number of regular bits set */
     int num6b = 0; /* pending 6-bit number */
@@ -79,21 +77,21 @@
 	switch (num6b) {
 	case 61:
 	    /* escape */
-	    put_digit(61);
+	    put_digit(base62, 61);
 	    /* extra "00...." high bits (in the next character) */
 	    bits2 = 2;
 	    bits6 = 0;
 	    num6b = 0;
 	    break;
 	case 62:
-	    put_digit(61);
+	    put_digit(base62, 61);
 	    /* extra "01...." high bits */
 	    bits2 = 2;
 	    bits6 = 0;
 	    num6b = 16;
 	    break;
 	case 63:
-	    put_digit(61);
+	    put_digit(base62, 61);
 	    /* extra "10...." high bits */
 	    bits2 = 2;
 	    bits6 = 0;
@@ -101,7 +99,7 @@
 	    break;
 	default:
 	    assert(num6b < 61);
-	    put_digit(num6b);
+	    put_digit(base62, num6b);
 	    bits2 = 0;
 	    bits6 = 0;
 	    num6b = 0;
@@ -110,7 +108,7 @@
     }
     if (bits6 + bits2) {
 	assert(num6b < 61);
-	put_digit(num6b);
+	put_digit(base62, num6b);
     }
     *base62 = '\0';
     return base62 - base62_start;
@@ -139,13 +137,8 @@
     C26('A', 'A' + 36),
 };
 
-/* Main base62 decoding routine: unpack base62 string into bitv[]. */
-static
-int decode_base62(const char *base62, char *bitv)
-{
-    char *bitv_start = bitv;
-    inline
-    void put6bits(int c)
+    static inline
+    void put6bits(char *bitv, int c)
     {
 	*bitv++ = (c >> 0) & 1;
 	*bitv++ = (c >> 1) & 1;
@@ -154,19 +147,25 @@
 	*bitv++ = (c >> 4) & 1;
 	*bitv++ = (c >> 5) & 1;
     }
-    inline
-    void put4bits(int c)
+    static inline
+    void put4bits(char *bitv, int c)
     {
 	*bitv++ = (c >> 0) & 1;
 	*bitv++ = (c >> 1) & 1;
 	*bitv++ = (c >> 2) & 1;
 	*bitv++ = (c >> 3) & 1;
     }
+
+/* Main base62 decoding routine: unpack base62 string into bitv[]. */
+static
+int decode_base62(const char *base62, char *bitv)
+{
+    char *bitv_start = bitv;
     while (1) {
 	long c = (unsigned char) *base62++;
 	int num6b = char_to_num[c];
 	while (num6b < 61) {
-	    put6bits(num6b);
+	    put6bits(bitv, num6b);
 	    c = (unsigned char) *base62++;
 	    num6b = char_to_num[c];
 	}
@@ -195,8 +194,8 @@
 	default:
 	    return -4;
 	}
-	put6bits(num6b);
-	put4bits(num4b);
+	put6bits(bitv, num6b);
+	put4bits(bitv, num4b);
     }
     return bitv - bitv_start;
 }
@@ -260,10 +259,7 @@
  * http://algo2.iti.uni-karlsruhe.de/singler/publications/cacheefficientbloomfilters-wea2007.pdf
  */
 
-/* Calculate Mshift paramter for encoding. */
-static
-int encode_golomb_Mshift(int c, int bpp)
-{
+    static
     int log2i(int n)
     {
 	int m = 0;
@@ -271,6 +267,11 @@
 	    m++;
 	return m;
     }
+
+/* Calculate Mshift paramter for encoding. */
+static
+int encode_golomb_Mshift(int c, int bpp)
+{
     /*
      * XXX Slightly better Mshift estimations are probably possible.
      * Recheck "Compression and coding algorithms" by Moffat & Turpin.
@@ -1340,18 +1341,8 @@
     set->c++;
 }
 
-/* This routine does the whole job. */
-const char * rpmsetFinish(rpmset set, int bpp)
-{
-    char * t = NULL;
-
-    if (set->c < 1 || bpp < 10 || bpp > 32) {
-if (_rpmset_debug)
-fprintf(stderr, "<-- %s(%p,%d) rc %s\n", __FUNCTION__, set, bpp, t);
-    }
-
-    unsigned mask = (bpp < 32) ? (1u << bpp) - 1 : ~0u;
     /* Jenkins' one-at-a-time hash */
+    static
     unsigned int hash(const char *str)
     {
 	unsigned int hash = 0x9e3779b9;
@@ -1367,12 +1358,8 @@
 	return hash;
     }
 
-    /* hash sv strings */
-    int i;
-    for (i = 0; i < set->c; i++)
-	set->sv[i].v = hash(set->sv[i].s) & mask;
-
     /* sort by hash value */
+    static
     int cmp(const void *arg1, const void *arg2)
     {
 	struct sv *sv1 = (struct sv *) arg1;
@@ -1383,6 +1370,36 @@
 	    return -1;
 	return 0;
     }
+
+    static
+    int uniqv(int c, unsigned *v)
+    {
+	int i, j;
+	for (i = 0, j = 0; i < c; i++) {
+	    while (i + 1 < c && v[i] == v[i+1])
+		i++;
+	    v[j++] = v[i];
+	}
+	return j;
+    }
+
+/* This routine does the whole job. */
+const char * rpmsetFinish(rpmset set, int bpp)
+{
+    char * t = NULL;
+
+    if (set->c < 1 || bpp < 10 || bpp > 32) {
+if (_rpmset_debug)
+fprintf(stderr, "<-- %s(%p,%d) rc %s\n", __FUNCTION__, set, bpp, t);
+    }
+
+    unsigned mask = (bpp < 32) ? (1u << bpp) - 1 : ~0u;
+
+    /* hash sv strings */
+    int i;
+    for (i = 0; i < set->c; i++)
+	set->sv[i].v = hash(set->sv[i].s) & mask;
+
     qsort(set->sv, set->c, sizeof *set->sv, cmp);
 
     /* warn on hash collisions */
@@ -1399,16 +1416,6 @@
     unsigned v[set->c];
     for (i = 0; i < set->c; i++)
 	v[i] = set->sv[i].v;
-    int uniqv(int c, unsigned *v)
-    {
-	int i, j;
-	for (i = 0, j = 0; i < c; i++) {
-	    while (i + 1 < c && v[i] == v[i+1])
-		i++;
-	    v[j++] = v[i];
-	}
-	return j;
-    }
     int c = uniqv(set->c, v);
     char base62[encode_set_size(c, bpp)];
     int len = encode_set(c, v, bpp, base62);
