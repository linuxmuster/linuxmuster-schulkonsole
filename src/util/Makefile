OS = Linux

VERSION = 0.31.0
CC      = /usr/bin/gcc
CFLAGS  = -Wall -g -D_REENTRANT -DVERSION=\"$(VERSION)\"

BUILDDIR = build
SOURCEDIR = .
EXECDIR = /usr/lib/schulkonsole/bin

SCRIPTS = $(wildcard $(SOURCEDIR)/*.pl)
SOURCES = $(wildcard $(SOURCEDIR)/*.c)
OBJECTS = $(patsubst $(SOURCEDIR)/%.c, $(BUILDDIR)/%.o, $(SOURCES))
BINARIES= $(patsubst $(SOURCEDIR)/%.c, $(BUILDDIR)/%, $(SOURCES))

ECHO = echo
RM = rm -rf
MKDIR = mkdir
INSTALL = install

.PHONY: all clean setup 

all: setup install clean

$(BUILDDIR)/%: $(BUILDDIR)/%.o
	$(CC) $(CFLAGS) -I$(SOURCEDIR) $< -o $@

$(BUILDDIR)/%.o: $(SOURCEDIR)/%.c setup
	$(CC) $(CFLAGS) -c $< -o $@

setup:
	$(MKDIR) -p $(BUILDDIR)
	$(MKDIR) -p $(DESTDIR)$(EXECDIR)

install_bin: $(BINARIES)
	for datei in $(patsubst $(BUILDDIR)/%,%,$(BINARIES)) ; do \
	    $(INSTALL) -m 4755 -o 0 -g 0 $(BUILDDIR)/$$datei $(DESTDIR)$(EXECDIR)/$$datei ; \
	done

install_script: $(SCRIPTS)
	for datei in $(SCRIPTS) ; do \
	    $(INSTALL) -m 755 -o 0 -g 0 $$datei $(DESTDIR)$(EXECDIR)/$$datei ; \
	done

install: install_bin install_script

clean:
	$(RM) $(BINARIES) $(OBJECTS)
	$(RM) -r $(BUILDDIR)

distclean: clean

help:
	@$(ECHO) "Targets:"
	@$(ECHO) "all     - buildcompile what is necessary"
	@$(ECHO) "clean   - cleanup old .o and binaries"
	@$(ECHO) "install - not yet fully supported"
