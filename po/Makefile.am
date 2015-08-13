AUTOMAKE_OPTIONS = foreign

SUFFIXES = .po .pot .mo

# these are the supported languages, 
ALL_LINGUAS = de en
POFILES = $(ALL_LINGUAS:=.po)
MSGFILES = $(ALL_LINGUAS:=.mo)

TEMPLATE = $(PACKAGE).pot

libpdpodir = $(pkglibdir)/po
libpdpo_DATA = $(MSGFILES)
dist_libpdpo_DATA =

EXTRA_DIST = $(POFILES)

# generate .mo files from the .po files
all-local: $(MSGFILES)



# refresh .po files from the template
clean-local:
	-rm -f -- $(MSGFILES)
	-rm -f -- $(POFILES:=~)
	-rm -f -- $(TEMPLATE)

po: $(POFILES)

# refresh the template from the source code
template: $(TEMPLATE)

$(TEMPLATE): POTFILES.tt.in
	$(XGETTEXT) \
	--from-code=UTF-8 --language=Python \
	--sort-by-file --output=$(TEMPLATE) \
	--package-name="schulkonsole" --package-version=$(VERSION) \
	--copyright-holder='This file is put in the public domain' \
	--msgid-bugs-address=fschuett@gymnasium-himmelsthuer.de \
	--keyword=get --files-from=POTFILES.tt.in

$(POFILES): %.po:
	$(MSGMERGE) --sort-by-file --update $< $(TEMPLATE)


%.mo: %.po
	$(MSGFMT) -o $*.mo  $<
