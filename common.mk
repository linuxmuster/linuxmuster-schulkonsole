PACKAGE = schulkonsole
VERSION = 0.31.0
DATADIR = /usr/share
LIBDIR  = /usr/lib/$(PACKAGE)
LOCALEDIR = $(DATADIR)/locale
SYSCONFDIR = /etc/linuxmuster
RUNTIMEDIR = /var/lib/schulkonsole

PERLLIBDIR = $(DATADIR)/$(PACKAGE)/Schulkonsole

# these are the supported languages, 
ALL_LINGUAS = de en

OS      = Linux
CC      = /usr/bin/gcc
ECHO    = echo
RM      = rm -rf
MKDIR   = mkdir
INSTALL = install

XGETTEXTTT = xgettext.pl
XGETTEXT   = xgettext
MSGMERGE   = msgmerge
MSGFMT     = msgfmt
