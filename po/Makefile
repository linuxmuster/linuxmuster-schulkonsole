SUFFIXES = .po .pot .mo
PACKAGE = schulkonsole

# use xgettext.pl for tt files
XGETTEXTTT = xgettext.pl
XGETTEXT   = xgettext
MSGMERGE   = msgmerge
MSGFMT     = msgfmt

# these are the supported languages, 
ALL_LINGUAS = de en
POFILES = $(ALL_LINGUAS:=.po)
MSGFILES = $(ALL_LINGUAS:=.mo)

TEMPLATE = $(PACKAGE).pot

libpdpodir = /usr/share/locale

EXTRA_DIST = $(POFILES)

INSTALL=install

build: $(MSGFILES)

# install
install: build
	for l in $(ALL_LINGUAS); do \
	    $(INSTALL) -m 644 -D $(addsuffix .mo,$$l) $(DESTDIR)$(libpdpodir)/$$l/LC_MESSAGES/$(PACKAGE).mo; \
	done

# refresh .po files from the template
clean:
	-rm -f -- $(MSGFILES)
	-rm -f -- $(POFILES:=~)
	-rm -f -- $(TEMPLATE)
	-rm -f -- POTFILES.tt.in
	-rm -f -- POTFILES.perl.in

messages: $(POFILES)

# refresh the template from the source code
template: $(TEMPLATE)

POTFILES.tt.in:
	find ..//menus.d -type f |sort >POTFILES.tt.in
	find ../tt -type f -name '*.tt' |sort >>POTFILES.tt.in

POTFILES.perl.in:
	find ../Schulkonsole -type f -name '*.pm*' |sort >POTFILES.perl.in
	find ../src/cgi-bin -type f -not -name 'Makefile.*' |sort >>POTFILES.perl.in

$(TEMPLATE): POTFILES.tt.in POTFILES.perl.in
	$(XGETTEXTTT) --plugin tt2 --gnu-gettext --use-gettext-style \
	--output=$(TEMPLATE) --files-from=POTFILES.tt.in
	sed 's/CHARSET/UTF-8/' -i $(TEMPLATE)
	$(XGETTEXT) --join-existing \
	--from-code=UTF-8 --language=Perl --output=$(TEMPLATE) \
	--package-name="schulkonsole" --package-version=$(VERSION) \
	--copyright-holder='This file is put in the public domain' \
	--msgid-bugs-address=fschuett@gymnasium-himmelsthuer.de \
	--keyword=get --files-from=POTFILES.perl.in

$(POFILES): $(TEMPLATE)
	$(MSGMERGE) -s $@ $< -o $@


%.mo: %.po
	$(MSGFMT) -f -o $@  $<
