PACKAGE = schulkonsole
VERSION = 0.31.0
srcdir = .
sysconfdir = /etc/linuxmuster
datadir = /usr/share
pkglibexecdir = /usr/lib/schulkonsole
pkgruntimedir = /var/lib/schulkonsole

perllibdir = /usr/share/schulkonsole/Schulkonsole
PERLFILES = $(wildcard *.pm) $(wildcard Error/*.pm) Session.pm Config.pm

GENERATED = Session.pm Config.pm

RM = rm -f
MAKE = make
INSTALL = install

clean:
	$(RM) $(GENERATED)


install: $(PERLFILES)
	for datei in $(PERLFILES) ; do \
	    $(INSTALL) -m 755 -o 0 -g 0 $$datei $(DESTDIR)$(perllibdir)/$$datei ; \
	done
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
