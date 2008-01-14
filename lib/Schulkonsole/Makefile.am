perllibdir = $(pkgdatadir)/Schulkonsole
perllib_DATA = Session.pm Config.pm
dist_perllib_DATA = DB.pm Error.pm ExternalError.pm Gettext.pm Template.pm \
	Room.pm RoomSession.pm \
	TeachIn.pm \
	Info.pm Firewall.pm Printer.pm Sophomorix.pm Cyrus.pm Collab.pm WWW.pm \
	Files.pm SophomorixQuotas.pm OVPN.pm

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

