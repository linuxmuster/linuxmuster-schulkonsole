#! /usr/bin/perl
use strict;
use HTML::Parser;



# fuer Perlcode:
# perl -ne 'print "#: stdin:${.}\nmsgid \"$3\"\nmsgstr \"\"\n\n" if (/\$(Schulkonsole::Common::)?_d->get\((.)(.*?)\2\)/ and $3)' start Schulkonsole/Common.pm logout
# oder: xgettext --lang=Perl --keyword=get


my $file;
foreach $file (@ARGV) {
	my $p = new HTML::Parser(
		api_version => 3,
		start_h => [\&start_tag_handler, 'tagname, attr'],
		end_h => [\&end_tag_handler, 'tagname, skipped_text'],
		marked_sections => 1,
		attr_encoded => 1,
	);
	$p->report_tags('gettext', 'title', 'input', 'optgroup');

	$p->parse_file($file);
}



sub start_tag_handler {
	my $tagname = shift;
	my $attr_ref = shift;

	if (    $tagname eq 'input'
	    and $$attr_ref{value}
	    and $$attr_ref{value} !~ m:^\$:) {
		print "get(\"$$attr_ref{value}\");\n";
	} elsif (    $tagname eq 'optgroup'
	         and $$attr_ref{label}) {
		print "get(\"$$attr_ref{label}\");\n";
	}
}


sub end_tag_handler {
	my $tagname = shift;
	my $skipped_text = shift;

    if ($tagname eq 'title') {
		my $p = new HTML::Parser(
			api_version => 3,
			start_h => [\&start_tag_handler,
			            "tagname, attr, text, skipped_text, '',
			             tokenpos"],
			end_h => [\&end_tag_handler, "tagname, skipped_text, text"],
			marked_sections => 1,
			attr_encoded => 1,
		);
		$p->report_tags('gettext');

		$p->parse($skipped_text);
		$p->eof;
	} elsif ($tagname ne 'optgroup') {
		$skipped_text =~ s/\n/\\n/g;
		$skipped_text =~ s/"/\\"/g;
		print "get(\"$skipped_text\");\n";
	}
}
