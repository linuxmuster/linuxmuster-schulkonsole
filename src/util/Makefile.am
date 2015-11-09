pkglibexecdir = $(libexecdir)/@PACKAGE@/bin
pkglibexec_PROGRAMS=wrapper-user wrapper-firewall wrapper-printer \
	wrapper-sophomorix wrapper-cyrus wrapper-files wrapper-ovpn \
	wrapper-linbo wrapper-radius wrapper-debconf
wrapper_user_SOURCES=wrapper-user.c
wrapper_cyrus_SOURCES=wrapper-cyrus.c
wrapper_firewall_SOURCES=wrapper-firewall.c
wrapper_printer_SOURCES=wrapper-printer.c
wrapper_sophomorix_SOURCES=wrapper-sophomorix.c
wrapper_files_SOURCES=wrapper-files.c
wrapper_ovpn_SOURCES=wrapper-ovpn.c
wrapper_linbo_SOURCES=wrapper-linbo.c
wrapper_radius_SOURCES=wrapper-radius.c
wrapper_debconf_SOURCES=wrapper-debconf.c
pkglibexec_SCRIPTS=wrapper-firewall.pl wrapper-printer.pl \
	wrapper-sophomorix.pl wrapper-files.pl wrapper-ovpn.pl \
	wrapper-linbo.pl wrapper-radius.pl wrapper-debconf.pl \
	wrapper-user.pl wrapper-cyrus.pl

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
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-debconf
	chmod -f 4755 $(DESTDIR)$(pkglibexecdir)/wrapper-cyrus


AM_CFLAGS = -DWRAPPERUSERAPP=\"$(pkglibexecdir)/wrapper-user.pl\" -DWRAPPERCYRUSAPP=\"$(pkglibexecdir)/wrapper-cyrus.pl\" -DWRAPPERFIREWALLPERLAPP=\"$(pkglibexecdir)/wrapper-firewall.pl\" -DWRAPPERPRINTERPERLAPP=\"$(pkglibexecdir)/wrapper-printer.pl\" -DWRAPPERSOPHOMORIXPERLAPP=\"$(pkglibexecdir)/wrapper-sophomorix.pl\" -DWRAPPERFILESPERLAPP=\"$(pkglibexecdir)/wrapper-files.pl\" -DWRAPPEROVPNPERLAPP=\"$(pkglibexecdir)/wrapper-ovpn.pl\" -DWRAPPERLINBOPERLAPP=\"$(pkglibexecdir)/wrapper-linbo.pl\" -DWRAPPERRADIUSPERLAPP=\"$(pkglibexecdir)/wrapper-radius.pl\" -DWRAPPERDEBCONFPERLAPP=\"$(pkglibexecdir)/wrapper-debconf.pl\"

