perllibdir = $(pkgdatadir)/Schulkonsole
perllib_DATA = Session.pm Config.pm
nobase_dist_perllib_DATA = \
	DB.pm \
	Error.pm ExternalError.pm \
	Error/Cyrus.pm \
	Error/Files.pm \
	Error/Firewall.pm \
	Error/Linbo.pm \
	Error/OVPN.pm \
	Error/Printer.pm \
	Error/Sophomorix.pm \
	Error/User.pm \
	Gettext.pm Template.pm \
	Room.pm RoomSession.pm \
	TeachIn.pm \
	Info.pm Firewall.pm Printer.pm Sophomorix.pm Cyrus.pm \
	Files.pm SophomorixQuotas.pm OVPN.pm Linbo.pm

CLEANFILES = $(perllib_DATA)
EXTRA_DIST = Session.pm.in Config.pm.in


pkglibexecdir = $(libexecdir)/@PACKAGE@
pkgruntimedir = /var/run/@PACKAGE@

install-am: all-am
	@$(MAKE) $(AM_MAKEFLAGS) install-exec-am install-data-am
	install -d -o www-data -g root -m 700 $(DESTDIR)$(pkgruntimedir)



do_subst = sed \
  -e 's,\@PACKAGE\@,$(PACKAGE),g' \
  -e 's,\@VERSION\@,$(VERSION),g' \
  -e 's,\@sysconfdir\@,$(sysconfdir),g' \
  -e 's,\@datadir\@,$(datadir),g' \
  -e 's,\@pkgruntimedir\@,$(pkgruntimedir),g' \
  -e 's,\@pkglibexecdir\@,$(pkglibexecdir),g'


%.pm: %.pm.in
	$(do_subst) $(srcdir)/$@.in > $@

