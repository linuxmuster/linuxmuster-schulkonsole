AUTOMAKE_OPTIONS = foreign

SUFFIXES = .po .pot .mo

# use xgettext.pl for tt files
XGETTEXTTT = xgettext.pl

# these are the supported languages, 
ALL_LINGUAS = de en
POFILES = $(ALL_LINGUAS:=.po)
MSGFILES = $(ALL_LINGUAS:=.mo)

TEMPLATE = $(PACKAGE).pot

libpdpodir = $(datarootdir)/locale

EXTRA_DIST = $(POFILES)

# install
install-data-hook:
	for l in $(ALL_LINGUAS); do \
	    $(INSTALL) -m 644 -D $(addsuffix .mo,$$l) $(DESTDIR)$(libpdpodir)/$$l/LC_MESSAGES/$(PACKAGE).mo; \
	done

# generate .mo files from the .po files
all-local: $(MSGFILES)



# refresh .po files from the template
clean-local:
	-rm -f -- $(MSGFILES)
	-rm -f -- $(POFILES:=~)
	-rm -f -- $(TEMPLATE)

messages: $(POFILES)

# refresh the template from the source code
template: $(TEMPLATE)

POTFILES.tt.in:
	find ../doc/lib/menus.d -type f |sort >POTFILES.tt.in
	find ../shtml -name '*.tt' |sort >>POTFILES.tt.in

POTFILES.perl.in:
	find ../lib/Schulkonsole -name '*.pm.*' |sort >POTFILES.perl.in
	find ../src/cgi-bin -not -name 'Makefile.*' |sort >>POTFILES.perl.in

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
