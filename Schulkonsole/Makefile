CURDIR=$(shell pwd)/..

include ../common.mk
srcdir = .

GENERATED = $(patsubst %.pm.in,%.pm,$(wildcard *.pm.in))

PERLFILES = $(wildcard *.pm) $(wildcard Error/*.pm) $(GENERATED)

PHPFILES  = $(wildcard *.php)

generate:
	$(RM) $(GENERATED)

build: generate $(GENERATED)

install: build
	for datei in $(PERLFILES) $(PHPFILES); do \
	    $(INSTALL) -D -m 755 -o 0 -g 0 $$datei $(DESTDIR)$(PERLLIBDIR)/$$datei ; \
	done
	install -d -o www-data -g root -m 700 $(DESTDIR)$(RUNTIMEDIR)
	chmod -f 755 $(DESTDIR)$(PERLLIBDIR)/horde-mail.php



do_subst = sed \
  -e 's,\@PACKAGE\@,$(PACKAGE),g' \
  -e 's,\@VERSION\@,$(VERSION),g' \
  -e 's,\@sysconfdir\@,$(SYSCONFDIR),g' \
  -e 's,\@datadir\@,$(DATADIR),g' \
  -e 's,\@pkgruntimedir\@,$(RUNTIMEDIR),g' \
  -e 's,\@pkglibexecdir\@,$(LIBDIR),g'


%.pm: %.pm.in
	$(do_subst) $(srcdir)/$@.in > $@

clean:
	$(RM) $(GENERATED)


