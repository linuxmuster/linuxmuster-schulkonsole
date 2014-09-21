pkglibexecdir = $(libexecdir)/@PACKAGE@/bin
pkglibexec_PROGRAMS=wrapper-user wrapper-firewall wrapper-printer \
	wrapper-sophomorix wrapper-cyrus wrapper-files wrapper-ovpn \
	wrapper-linbo wrapper-radius
wrapper_user_SOURCES=wrapper-user.c
wrapper_firewall_SOURCES=wrapper-firewall.c
wrapper_printer_SOURCES=wrapper-printer.c
wrapper_sophomorix_SOURCES=wrapper-sophomorix.c
wrapper_files_SOURCES=wrapper-files.c
wrapper_ovpn_SOURCES=wrapper-ovpn.c
wrapper_linbo_SOURCES=wrapper-linbo.c
wrapper_radius_SOURCES=wrapper-radius.c
dist_pkglibexec_SCRIPTS=quota.pl cyrquota.pl
pkglibexec_SCRIPTS=wrapper-firewall.pl wrapper-printer.pl \
	wrapper-sophomorix.pl wrapper-files.pl wrapper-ovpn.pl \
	wrapper-linbo.pl wrapper-radius.pl
CLEANFILES=$(pkglibexec_SCRIPTS)
EXTRA_DIST=wrapper-firewall.pl.in wrapper-printer.pl.in \
	wrapper-sophomorix.pl.in wrapper-files.pl.in wrapper-ovpn.pl.in \
	wrapper-linbo.pl.in wrapper-radius.pl.in


do_subst = sed \
  -e 's,\@PACKAGE\@,$(PACKAGE),g' \
  -e 's,\@datadir\@,$(datadir),g'

%: %.in
	$(do_subst) $(srcdir)/$@.in > $@


install-am: all-am
	@$(MAKE) $(AM_MAKEFLAGS) install-exec-am install-data-am
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-user
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-firewall
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-printer
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-sophomorix
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-files
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-ovpn
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-linbo
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-radius

AM_CFLAGS = -DQUOTAAPP=\"$(pkglibexecdir)/quota.pl\" -DCYRQUOTAAPP=\"$(pkglibexecdir)/cyrquota.pl\" -DWRAPPERFIREWALLPERLAPP=\"$(pkglibexecdir)/wrapper-firewall.pl\" -DWRAPPERPRINTERPERLAPP=\"$(pkglibexecdir)/wrapper-printer.pl\" -DWRAPPERSOPHOMORIXPERLAPP=\"$(pkglibexecdir)/wrapper-sophomorix.pl\" -DWRAPPERFILESPERLAPP=\"$(pkglibexecdir)/wrapper-files.pl\" -DWRAPPEROVPNPERLAPP=\"$(pkglibexecdir)/wrapper-ovpn.pl\" -DWRAPPERLINBOPERLAPP=\"$(pkglibexecdir)/wrapper-linbo.pl\" -DWRAPPERRADIUSPERLAPP=\"$(pkglibexecdir)/wrapper-radius.pl\"

