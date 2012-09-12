require 'formula'

class Rpm < Formula
  homepage 'http://www.rpm.org/'
  url 'http://rpm.org/releases/rpm-4.10.x/rpm-4.10.0.tar.bz2'
  sha1 'd78f19194066c3895f91f58dc84e3aad69f0b02c'

  depends_on 'nss'
  depends_on 'nspr'
  depends_on 'libmagic'
  depends_on 'popt'
  depends_on 'lua'
  depends_on 'berkeley-db'
  depends_on 'xz'

  # setprogname conflicts with setprogname(3), weak_alias not supported
  # add compatibility with lua 5.2, in addition to the default lua 5.1
  def patches
    DATA
  end

  def install
    ENV.append 'CPPFLAGS', "-I#{HOMEBREW_PREFIX}/include/nss -I#{HOMEBREW_PREFIX}/include/nspr"
    # pkg-config support was removed from lua 5.2:
    ENV['LUA_CFLAGS'] = "-I#{HOMEBREW_PREFIX}/include"
    ENV['LUA_LIBS'] = "-L#{HOMEBREW_PREFIX}/lib -llua"
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}", "--with-lua", "--with-external-db", "--sysconfdir=#{HOMEBREW_PREFIX}/etc", "--without-hackingdocs", "--enable-python", "--localstatedir=#{HOMEBREW_PREFIX}/var"
    system "make"
    system "make install"
    # the default install makes /usr/bin/rpmquery a symlink to /bin/rpm
    # by using ../.. but that doesn't really work with any other prefix.
    ln_sf "rpm", "#{bin}/rpmquery"
    ln_sf "rpm", "#{bin}/rpmverify"
  end
end

__END__
diff --git a/lib/poptALL.c b/lib/poptALL.c
index d2db871..e02094b 100644
--- a/lib/poptALL.c
+++ b/lib/poptALL.c
@@ -234,7 +234,7 @@ rpmcliInit(int argc, char *const argv[], struct poptOption * optionsTable)
     int rc;
     const char *ctx, *execPath;
 
-    setprogname(argv[0]);       /* Retrofit glibc __progname */
+    xsetprogname(argv[0]);       /* Retrofit glibc __progname */
 
     /* XXX glibc churn sanity */
     if (__progname == NULL) {
diff --git a/misc/glob.c b/misc/glob.c
index 3bebe9e..921b8c0 100644
--- a/misc/glob.c
+++ b/misc/glob.c
@@ -944,6 +944,11 @@ __glob_pattern_p (const char *pattern, int quote)
 }
 # ifdef _LIBC
 weak_alias (__glob_pattern_p, glob_pattern_p)
+# else
+int glob_pattern_p (__const char *__pattern, int __quote)
+{
+    return __glob_pattern_p(__pattern, __quote);
+}
 # endif
 #endif
 
diff --git a/rpm2cpio.c b/rpm2cpio.c
index 89ebdfa..f35c7c8 100644
--- a/rpm2cpio.c
+++ b/rpm2cpio.c
@@ -21,7 +21,7 @@ int main(int argc, char *argv[])
     off_t payload_size;
     FD_t gzdi;
     
-    setprogname(argv[0]);	/* Retrofit glibc __progname */
+    xsetprogname(argv[0]);	/* Retrofit glibc __progname */
     rpmReadConfigFiles(NULL, NULL);
     if (argc == 1)
 	fdi = fdDup(STDIN_FILENO);
diff --git a/rpmqv.c b/rpmqv.c
index da5f2ca..d033d21 100644
--- a/rpmqv.c
+++ b/rpmqv.c
@@ -92,8 +92,8 @@ int main(int argc, char *argv[])
 
     /* Set the major mode based on argv[0] */
 #ifdef	IAM_RPMQV
-    if (rstreq(__progname, "rpmquery"))	bigMode = MODE_QUERY;
-    if (rstreq(__progname, "rpmverify")) bigMode = MODE_VERIFY;
+    if (rstreq(__progname ? __progname : "", "rpmquery"))	bigMode = MODE_QUERY;
+    if (rstreq(__progname ? __progname : "", "rpmverify")) bigMode = MODE_VERIFY;
 #endif
 
 #if defined(IAM_RPMQV)
diff --git a/system.h b/system.h
index dd35738..78dec9f 100644
--- a/system.h
+++ b/system.h
@@ -21,6 +21,7 @@
 #ifdef __APPLE__
 #include <crt_externs.h>
 #define environ (*_NSGetEnviron())
+#define fdatasync fsync
 #else
 extern char ** environ;
 #endif /* __APPLE__ */
@@ -114,10 +115,10 @@ typedef	char * security_context_t;
 #if __GLIBC_MINOR__ >= 1
 #define	__progname	__assert_program_name
 #endif
-#define	setprogname(pn)
+#define	xsetprogname(pn)
 #else
 #define	__progname	program_name
-#define	setprogname(pn)	\
+#define	xsetprogname(pn)	\
   { if ((__progname = strrchr(pn, '/')) != NULL) __progname++; \
     else __progname = pn;		\
   }
#######################################################################
diff --git a/luaext/lposix.c b/luaext/lposix.c
index 3b25157..f3c787e 100644
--- a/luaext/lposix.c
+++ b/luaext/lposix.c
@@ -810,7 +810,7 @@ static int Pmkstemp(lua_State *L)
 	return 2;
 }
 
-static const luaL_reg R[] =
+static const luaL_Reg R[] =
 {
 	{"access",		Paccess},
 	{"chdir",		Pchdir},
@@ -874,15 +874,19 @@ static int exit_override(lua_State *L)
     exit(luaL_optint(L, 1, EXIT_SUCCESS));
 }
 
-static const luaL_reg os_overrides[] =
+static const luaL_Reg os_overrides[] =
 {
     {"exit",    exit_override},
     {NULL,      NULL}
 };
 
+#ifndef lua_pushglobaltable
+#define lua_pushglobaltable(L) lua_pushvalue(L, LUA_GLOBALSINDEX)
+#endif
+
 int luaopen_rpm_os(lua_State *L)
 {
-    lua_pushvalue(L, LUA_GLOBALSINDEX);
+    lua_pushglobaltable(L);
     luaL_openlib(L, "os", os_overrides, 0);
     return 0;
 }
diff --git a/luaext/lrexlib.c b/luaext/lrexlib.c
index 81931c0..9da5c82 100644
--- a/luaext/lrexlib.c
+++ b/luaext/lrexlib.c
@@ -169,7 +169,7 @@ static int rex_gc (lua_State *L)
   return 0;
 }
 
-static const luaL_reg rexmeta[] = {
+static const luaL_Reg rexmeta[] = {
   {"match",   rex_match},
   {"gmatch",  rex_gmatch},
   {"__gc",    rex_gc},
@@ -305,7 +305,7 @@ static const luaL_reg pcremeta[] = {
 
 /* Open the library */
 
-static const luaL_reg rexlib[] = {
+static const luaL_Reg rexlib[] = {
 #ifdef WITH_POSIX
   {"newPOSIX", rex_comp},
 #endif
diff --git a/rpmio/rpmlua.c b/rpmio/rpmlua.c
index 319c0d0..86d0408 100644
--- a/rpmio/rpmlua.c
+++ b/rpmio/rpmlua.c
@@ -7,6 +7,18 @@
 #include <lposix.h>
 #include <lrexlib.h>
 
+#ifndef lua_open
+#define lua_open()	luaL_newstate()
+#endif
+
+#ifndef lua_strlen
+#define lua_strlen(L,i)	lua_rawlen(L, (i))
+#endif
+
+#ifndef lua_pushglobaltable
+#define lua_pushglobaltable(L)	lua_pushvalue(L, LUA_GLOBALSINDEX)
+#endif
+
 #include <unistd.h>
 #include <assert.h>
 
@@ -53,10 +65,10 @@ rpmlua rpmluaNew()
 {
     rpmlua lua = (rpmlua) xcalloc(1, sizeof(*lua));
     struct stat st;
-    const luaL_reg *lib;
+    const luaL_Reg *lib;
     char *initlua = rpmGenPath(rpmConfigDir(), "init.lua", NULL);
    
-    static const luaL_reg extlibs[] = {
+    static const luaL_Reg extlibs[] = {
 	{"posix", luaopen_posix},
 	{"rex", luaopen_rex},
 	{"rpm", luaopen_rpm},
@@ -74,12 +86,26 @@ rpmlua rpmluaNew()
 	lua_call(L, 1, 0);
 	lua_settop(L, 0);
     }
+#ifndef LUA_GLOBALSINDEX
+    lua_pushglobaltable(L);
+#endif
     lua_pushliteral(L, "LUA_PATH");
     lua_pushfstring(L, "%s/%s", rpmConfigDir(), "/lua/?.lua");
+#ifdef LUA_GLOBALSINDEX
     lua_rawset(L, LUA_GLOBALSINDEX);
+#else
+    lua_settable(L, -3);
+#endif
     lua_pushliteral(L, "print");
     lua_pushcfunction(L, rpm_print);
+#ifdef LUA_GLOBALSINDEX
     lua_rawset(L, LUA_GLOBALSINDEX);
+#else
+    lua_settable(L, -3);
+#endif
+#ifndef LUA_GLOBALSINDEX
+    lua_pop(L, 1);
+#endif
     rpmluaSetData(lua, "lua", lua);
     if (stat(initlua, &st) != -1)
 	(void)rpmluaRunScriptFile(lua, initlua);
@@ -191,7 +217,7 @@ void rpmluaSetVar(rpmlua _lua, rpmluav var)
     }
     if (!var->listmode || lua->pushsize > 0) {
 	if (lua->pushsize == 0)
-	    lua_pushvalue(L, LUA_GLOBALSINDEX);
+	    lua_pushglobaltable(L);
 	if (pushvar(L, var->keyType, &var->key) != -1) {
 	    if (pushvar(L, var->valueType, &var->value) != -1)
 		lua_rawset(L, -3);
@@ -228,7 +254,7 @@ void rpmluaGetVar(rpmlua _lua, rpmluav var)
     lua_State *L = lua->L;
     if (!var->listmode) {
 	if (lua->pushsize == 0)
-	    lua_pushvalue(L, LUA_GLOBALSINDEX);
+	    lua_pushglobaltable(L);
 	if (pushvar(L, var->keyType, &var->key) != -1) {
 	    lua_rawget(L, -2);
 	    popvar(L, &var->valueType, &var->value);
@@ -261,7 +287,7 @@ static int findkey(lua_State *L, int oper, const char *key, va_list va)
     vsnprintf(buf, blen + 1, key, va);
 
     s = e = buf;
-    lua_pushvalue(L, LUA_GLOBALSINDEX);
+    lua_pushglobaltable(L);
     for (;;) {
 	if (*e == '\0' || *e == '.') {
 	    if (e != s) {
@@ -822,7 +848,7 @@ static int rpm_print (lua_State *L)
     return 0;
 }
 
-static const luaL_reg rpmlib[] = {
+static const luaL_Reg rpmlib[] = {
     {"b64encode", rpm_b64encode},
     {"b64decode", rpm_b64decode},
     {"expand", rpm_expand},
@@ -836,7 +862,7 @@ static const luaL_reg rpmlib[] = {
 
 static int luaopen_rpm(lua_State *L)
 {
-    lua_pushvalue(L, LUA_GLOBALSINDEX);
+    lua_pushglobaltable(L);
     luaL_openlib(L, "rpm", rpmlib, 0);
     return 0;
 }
diff --git a/lib/rpmliblua.c b/lib/rpmliblua.c
index 046ed31..c9b04da 100644
--- a/lib/rpmliblua.c
+++ b/lib/rpmliblua.c
@@ -23,16 +23,26 @@ static int rpm_vercmp(lua_State *L)
     return rc;
 }
 
-static const luaL_reg luarpmlib_f[] = {
+static const luaL_Reg luarpmlib_f[] = {
     {"vercmp", rpm_vercmp},
     {NULL, NULL}
 };
 
+#ifndef lua_pushglobaltable
+#define lua_pushglobaltable(L) lua_pushvalue(L, LUA_GLOBALSINDEX)
+#endif
+
 void rpmLuaInit(void)
 {
     rpmlua lua = rpmluaGetGlobalState();
-    lua_pushvalue(lua->L, LUA_GLOBALSINDEX); 
+    lua_pushglobaltable(lua->L); 
+#if (LUA_VERSION_NUM < 502) || defined(LUA_COMPAT_MODULE)
     luaL_register(lua->L, "rpm", luarpmlib_f);
+#else
+    luaL_pushmodule(lua->L, "rpm", 1);
+    lua_insert(lua->L, -1);
+    luaL_setfuncs(lua->L, luarpmlib_f, 0);
+#endif
     return;
 }
 
