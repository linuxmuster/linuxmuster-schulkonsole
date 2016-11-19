AC_INIT([schulkonsole], [0.19.0-12])
AC_CONFIG_AUX_DIR(config)
AM_INIT_AUTOMAKE

AM_GNU_GETTEXT([external])
AC_DEFINE(HAVE_CATGETS)
AC_DEFINE(ENABLE_NLS)
AC_DEFINE(HAVE_LC_MESSAGES)
AC_DEFINE(HAVE_STPCPY)

localedir=${datadir}/locale
AC_SUBST(localedir)

AC_OUTPUT([Makefile
	src/Makefile
	src/cgi-bin/Makefile
	src/util/Makefile
	shtml/Makefile
	lib/Makefile
	lib/Schulkonsole/Makefile
	bin/Makefile
	linbo/Makefile
	linbo/templates/Makefile
	linbo/templates/os/Makefile
	linbo/templates/part/Makefile
	po/Makefile])

