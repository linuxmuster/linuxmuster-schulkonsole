perllibdir = $(pkgdatadir)/Schulkonsole
perllib_DATA = Session.pm Config.pm
nobase_dist_perllib_DATA = \
	Cyrus.pm \
	DB.pm \
	Debconf.pm \
	Encode.pm \
	Error/Error.pm \
	Error/ExternalError.pm \
	Error/Cyrus.pm \
	Error/Files.pm \
	Error/Firewall.pm \
	Error/Linbo.pm \
	Error/OVPN.pm \
	Error/Printer.pm \
	Error/Radius.pm \
	Error/SophomorixError.pm \
	Error/User.pm \
	Error/Horde.pm \
	Error/Debconf.pm \
	Files.pm \
	Firewall.pm \
	Gettext.pm \
	Horde.pm \
	Info.pm \
	Lesson.pm \
	LessonSession.pm \
	Linbo.pm \
	OVPN.pm \
	Printer.pm \
	Radius.pm \
	Room.pm \
	RoomSession.pm \
	Sophomorix.pm \
	SophomorixQuotas.pm \
	TeachIn.pm \
	Wrapper.pm \
	File.php \
	Session.php \
	Template.php \
	Wrapper.php \
	horde-mail.php

CLEANFILES = $(perllib_DATA)
EXTRA_DIST = Session.pm.in Config.pm.in


pkglibexecdir = $(libexecdir)/@PACKAGE@
pkgruntimedir = /var/lib/@PACKAGE@

install-am: all-am
	@$(MAKE) $(AM_MAKEFLAGS) install-exec-am install-data-am
	install -d -o www-data -g root -m 700 $(DESTDIR)$(pkgruntimedir)
	chmod -f 755 $(DESTDIR)$(perllibdir)/horde-mail.php



do_subst = sed \
  -e 's,\@PACKAGE\@,$(PACKAGE),g' \
  -e 's,\@VERSION\@,$(VERSION),g' \
  -e 's,\@sysconfdir\@,$(sysconfdir),g' \
  -e 's,\@datadir\@,$(datadir),g' \
  -e 's,\@pkgruntimedir\@,$(pkgruntimedir),g' \
  -e 's,\@pkglibexecdir\@,$(pkglibexecdir),g'


%.pm: %.pm.in
	$(do_subst) $(srcdir)/$@.in > $@

