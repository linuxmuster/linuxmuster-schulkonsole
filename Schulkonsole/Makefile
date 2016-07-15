CURDIR=$(shell pwd)/..

include ../common.mk
srcdir = .

PERLFILES = $(wildcard *.pm) $(wildcard Error/*.pm) $(GENERATED)

PHPFILES  = $(wildcard *.php)

build:
	sed -i 's@^\$$_version = .*@\$$_version = '\''$(VERSION)'\'';@' Config.pm

install: build
	for datei in $(PERLFILES) $(PHPFILES); do \
	    $(INSTALL) -D -m 755 -o 0 -g 0 $$datei $(DESTDIR)$(PERLLIBDIR)/$$datei ; \
	done
	install -d -o www-data -g root -m 700 $(DESTDIR)$(RUNTIMEDIR)
	chmod -f 755 $(DESTDIR)$(PERLLIBDIR)/horde-mail.php


