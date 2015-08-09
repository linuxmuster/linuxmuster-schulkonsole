use strict;
use POSIX;
use HTML::Parser;
use HTML::Entities;
use Schulkonsole::Config;

package Schulkonsole::Template;

=head1 NAME

Schulkonsole::Template - HTML-templates for schulkonsole

=head1 SYNOPSIS

Schulkonsole::Template implements the schulkonsole template system.
It supports simple variable substitution, conditionals based on variable
definition, and gettext for internationalisation.


=head1 DESCRIPTION

The only public function C<print_page()> needs a Schulkonsole::Session object
as the first parameter. Usually this function is indirectly invoked by
invoking C<Schulkonsole::Session::print_page()>.

=head2 The template format

The syntax of the template format is a subset of SSI (Server Side Includes).
All commands are of the form
C<< <!--#COMMAND parameter-name="parameter-value" --> >>.

=head3 Commands

The commands are the following:

=over

=item C<echo>

Simply prints the value of the attribute C<var>. This is a variable name
that is set by schulkonsole or the C<set>-command.

Example: C<< <!--#echo var="username" --> >>

=item C<include>

Includes the file specified by the attribute C<file>.
The file may itself be a template.
The location of the file must be in the schulkonsole template directory and
may not contain the special directory name C<..> or begin with C</>.

Example C<< <!--#include file="menu.shtml.inc" --> >>

=item C<if>

This implements basic conditionals. The parameter C<expr>
contains a variable.
The variable begins with C<$>.
If the variable is set the part after C<< <!--#if ... --> >> up to the next
C<< <!--#else --> >> or C<< <!--#endif --> >> is parsed. If parsing stopped
at C<< <!--#else --> >> then the part after C<< <!--#else --> >> up to
the next C<< <!--#endif --> >> is skipped.

If the variable is not set, the first part is skipped and the second part
(if present) is parsed.

Nesting conditionals is possible.

Example:
  <!--#if expr="$username"-->
      username: <!--#echo var="username" -->
  <!--#else -->
      No username.
  <!--#endif -->

=item C<if>-loop

Simple loops to iterate over the values of an array are also implemented with
the C<if>-command.

If the C<expr>-attribute starts with C<$loop_> the remainder of the attribute
value is taken to be a reference to an array.
Within the loop the current value is accessible by the name of this array.

Example:
  <!--#if expr="$loop_rows"-->
      <!--#echo var="rows" -->
  <!--#endif -->

=item C<set>

Sets the variable with the value of the attribute C<var> to the value of the
value of the attribute C<value>.

Example:
  <!--#set var="n" value="100" -->

=back


=head3 Variables

Apart from the template commands template variables are interpolated in the
attributes C<name>, C<value>, and C<id> of the HTML-tag C<input>,
in the attribute C<for> of the HTML-tag C<label>,
in the attribute C<value> of the HTML-tag C<option>,
in the attributes C<style> and C<title> of the HTML-tag C<span>,
in the attribute C<href> of the HTML-tag C<a>,
and in the attribute C<action> of the HTML-tag C<form>.
The value of the attribute C<id> will be converted to a valid string if
necessary.

The attribute value must start with a variable.

Valid characters for simple variable names are all alphanumeric characters
and underscore (C<_>).
Hash values are accessible by appending the name of the value within
curly braces to the variable.
Array values are accessible by appending the index of the value within
square braces to the variable.

Example:
  <input name="$name">
  <input name="${name}_comment">

  <select name="printjobs" multiple>
  <!--#if expr="$loop_printjobs" -->
      <option value="$printjobs{id}">
          <!--#echo var="printjobs{id}" --> <!--#echo var="printjobs{title}" -->
      </option>
  <!--#endif -->


=head3 Form values

In some tags the parameters passed in the CGI-object of the CGI::Session are
evaluated.


C<input>-fields of types C<text> and C<hidden> are filled with the value
in the parameters.

In a group of radio buttons (C<input>-fields of type C<radio>) the button
with the value passed in the parameters is checked.

In C<select> the C<option> selected in the parameters is selected.


=head3 Gettext

schulkonsole templates introduce a new tag C<< <gettext> >>. The content
between opening and ending tag will be translated by the gettext system,
if a translation is present. Otherwise the original content is used.

The content may NOT include the following tags:
C<< <div> >>,
C<< <form> >>,
C<< <input> >>,
C<< <label> >>,
C<< <gettext> >>.

Other strings that are translated and need not be marked with C<< <gettext> >>
are the values of C<< <input> >> fields.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	print_page
);

# package variables
my $_query;
my @_if_states;
my @_skip_states;
my $_do_html_skip = 0;
my $_do_buffer = 0;
my $_parent_page;
my %_template_vars;
my $_is_error;
my %_input_errors;
my $_d;
my $_lang;
my $_no_cookies = 0;
my $_session_id;
my $_html_buffer = '';
my $_html_string = '';
my $_var_loop;
my $_in_gettext;
my $_skip_buffer;
my $_element_name;



sub get_jquery_dialog {
	my $title = shift;
	my $message = shift;
	my $function = "\n". ' <script>
  $(function() {
    $( "#dialog-message" ).dialog({
      modal: true,
      buttons: {
        Ok: function() {
          $( this ).dialog( "close" );
        }
      }
    }).position({
      my: "center",
      at: "center",
    });
  });
  </script>
';
	my $dialog = '<div id="dialog-message" title="'.$title.'">
  <p>
    <span class="ui-icon ui-icon-alert" style="float:left; margin:0 7px 50px 0;"></span>
    '.$message.'
  </p>
</div>
';
	return $function . $dialog;
}

sub print_page {
	my $sk_session = shift;

	my $filename = shift;
	my $action = shift;


	binmode(STDOUT, ":utf8");

	$_query = $sk_session->{query};

	# if we have path-info the links within the page will not work
	# we should not be here
	my $path = $_query->path_info();
	if ($path) {
		my $url = $_query->url( -absolute => 1 );
		$url =~ s:/+$::; # delete multiple / remaining from path-info
		print $_query->redirect( -uri => $url,
		                         -status => 303 );

		exit;
	}

	%_template_vars = %{ $sk_session->{template_vars} };
	$_parent_page = $sk_session->{parent_page};
	$_is_error = $sk_session->{is_error};
	$_d = $sk_session->{d};
	$_lang = $sk_session->{lang};
	%_input_errors = %{ $sk_session->{input_errors} };
	$_session_id = $sk_session->{session}->id;

	my $old_session_id = $_query->cookie(CGI::Session->name());
	$_no_cookies = 1 unless ($old_session_id or $sk_session->{logout});

	if ($sk_session->{logout}) {
		my @cookies = (
			$_query->cookie(
				-name => $sk_session->{session}->name,
				-value => 'expired',
				-expires => 'now',
				-path => $Schulkonsole::Config::_http_root,
				-secure => 1,
			),
			$_query->cookie(
				-name => 'key',
				-value => 'expired',
				-expires => 'now',
				-path => $Schulkonsole::Config::_http_root,
				-secure => 1,
			),
		);
		print $_query->header( -cookie => \@cookies,
		                       -expires => 'now' );
	} elsif (   $_no_cookies
	         or $_session_id ne $old_session_id) {
		my $cookie = $_query->cookie(
			-name => $sk_session->{session}->name,
			-value => $_session_id,
			-path => $Schulkonsole::Config::_http_root,
			-secure => 1,
		);
		print $_query->header( -cookie => $cookie,
		                       -expires => 'now' );
	} elsif ($sk_session->{key}) {
		my $cookie = $_query->cookie(
			-name => 'key',
			-value => $sk_session->{key},
			-path => $Schulkonsole::Config::_http_root,
			-secure => 1,
		);
		print $_query->header( -cookie => $cookie,
		                       -expires => 'now' );
	} else {
		print $_query->header( -expires => 'now' );
	}


	my $p = new HTML::Parser(
		api_version => 3,
		start_h => [\&start_tag_handler,
		            "tagname, attr, text, skipped_text, '$action', tokenpos"],
		end_h => [\&end_tag_handler, "tagname, skipped_text, text"],
		comment_h => [\&comment_handler, "skipped_text, text, '$action'"],
		end_document_h => [\&comment_handler, "skipped_text"],
		marked_sections => 1,
		attr_encoded => 1,
	);
	$p->report_tags('body', 'div', 'label', 'form', 'input', 'textarea', 'select',
	                'option', 'optgroup',
	                'th', 'title', 'meta', 'html', 'span', 'a', 'gettext');

	$p->parse_file("$Schulkonsole::Config::_templatedir/$filename")
		or die "$0: Cannot parse $Schulkonsole::Config::_templatedir/$filename: $!\n";

	my $p_content = new HTML::Parser(
		api_version => 3,
		start_h => [\&content_start_tag_handler,
		            "tagname, attr, skipped_text, text, '$action',
		             tokenpos"],
		end_document_h => [\&content_end_document_handler, "skipped_text"],
		marked_sections => 1,
		attr_encoded => 1,
	);
	$p_content->report_tags('a');

	$p_content->parse($_html_string);
	$p_content->eof;
}




sub substitute_token {
	my $text = shift;
	my $tokenpos = shift;
	my $key_values = shift;

	my %no_value_keys = (
		checked => 1,
		selected => 1,
	);

	my $content = '<' . substr($text, $$tokenpos[0], $$tokenpos[1]);

	for (my $i = 2; $i < $#$tokenpos; $i += 4) {
		my $is_substituted = 0;

		foreach my $key (keys %$key_values) {
			if (substr($text, $$tokenpos[$i], $$tokenpos[$i + 1]) =~ /^$key$/i) {
				$is_substituted = 1;

				if ($no_value_keys{$key}) {
					if (not $$key_values{$key}) {
						$content .= ' ';
					} else {
						$content .= ' '
							. substr($text, $$tokenpos[$i], $$tokenpos[$i + 1]);
					}
				} else {
					$content .= ' '
						. substr($text, $$tokenpos[$i], $$tokenpos[$i + 1])
						. '="' . $$key_values{$key} . '"';
				}
				delete $$key_values{$key};
				last;
			}
		}
		if (not $is_substituted) {
			$content .= ' '
				. substr($text, $$tokenpos[$i], $$tokenpos[$i + 1]);
			$content .= '='
				. substr($text, $$tokenpos[$i + 2], $$tokenpos[$i + 3])
				if $$tokenpos[$i + 3];
		}
	}
	foreach my $key (keys %$key_values) {
		if ($no_value_keys{$key}) {
			if ($$key_values{$key}) {
				$content .= ' ' . $key;
			}
		} else {
			$content .= ' ' . $key . '="' . $$key_values{$key} . '"';
		}
	}
	$content .= '>';

	return $content;
}




sub start_tag_handler {
	return if $_do_html_skip;

	my $tagname = shift;
	my $attr_ref = shift;
	my $text = shift;
	my $skipped_text = shift;
	my $action = shift;
	my $tokenpos = shift;

	if ($_in_gettext) {
		$_skip_buffer .= $skipped_text . $text;
	} else {
		print_content($skipped_text);

		if ($tagname eq 'gettext') {
			$_in_gettext = 1;
        } elsif ($tagname eq 'body') {
            print_content("<body id=\"$action\">");
		} elsif ($tagname eq 'form') {
			my $anchor = $1 if $$attr_ref{action} =~ s/(#[^#]*)//;
			if (not $$attr_ref{action}) {
				print_content(
					substitute_token($text, $tokenpos,
						{ action => CGI->escapeHTML($action) . $anchor }));
			} elsif (my ($action, $path) = $$attr_ref{action} =~ m:^(.+)/(\$.+):) {
				my $new_path = substitute_vars($path);
				print_content(
					substitute_token($text, $tokenpos,
						{ action => CGI->escapeHTML("$action/$new_path") . $anchor }));
			} else {
				print_content($text);
			}
		} elsif ($tagname eq 'input') {
			if (not $_do_buffer) {
				my $subst = {};

				my $id = $$attr_ref{id};
				if (    $id
				    and my $new_id = substitute_vars($id)) {
					$new_id =~ s/[^A-Za-z0-9\-_:.]//g;
					$new_id =~ s/^([^A-Za-z])/x$1/;
					$$subst{id} = $new_id if $new_id ne $id;
				}
				my $name = $$attr_ref{name};
				if (    $name
				    and my $new_name = substitute_vars($name)) {
					if ($new_name ne $name) {
						$$subst{name} = HTML::Entities::encode_entities(CGI->escapeHTML($new_name));
						$name = $new_name;
					}
				}

				my @values = $_query->param($name)
					if ($name and defined $_query->param($name));
				if (    @values == 1	# substitute unique values only
				    and (   not defined $$attr_ref{type} 
				         or $$attr_ref{type} eq 'text'
				         or $$attr_ref{type} eq 'hidden')) {
					$$subst{value} = CGI->escapeHTML($values[0]);
					print_content(substitute_token($text, $tokenpos, $subst));
			    } else {
					if (defined $$attr_ref{value}) {
						# substitute template variables in attribute "value"
						my $value = $$attr_ref{value};
						my $new_value = substitute_vars($value);
						if (    defined $new_value
						    and $new_value ne $value) {
							$$subst{value} = CGI->escapeHTML($new_value);
						} else {
							# if "value" contained no variables, use gettext
							$$subst{value} = $_d->get($value);
						}

						# check last checked radio-button
						if (    @values == 1
						    and $$attr_ref{type} eq 'radio') {
							my $checked = $values[0];
							my $is_checked = $$attr_ref{checked};

							if ($is_checked) {
								$$subst{checked} = 0
									if $checked ne $$subst{value};
							} else {
								$$subst{checked} = 1
									if $checked eq $$subst{value};
							}
						}

					}

					if (%$subst) {
						print_content(substitute_token($text, $tokenpos, $subst));
					} else {
						print_content($text);
					}
					if (    $_no_cookies
					    and lc($$attr_ref{type}) eq 'submit') {
						print_content('<input type="hidden" name="'
							. CGI::Session->name() . '" value="' . $_session_id . '">');
					}
				}
			} else {
				print_content($text);
			}
		} elsif ($tagname eq 'label') {
			if (    not $_do_buffer
				and my $for = $$attr_ref{for}) {
				my $subst = {};

				if (    $for
				    and my $new_for = substitute_vars($for)) {
					$new_for =~ s/[^A-Za-z0-9\-_:.]//g;
					$new_for =~ s/^([^A-Za-z])/x$1/;
					if ($new_for ne $for) {
						$$subst{for} = $new_for;
						$for = $new_for;
					}
				}
				if (defined $_input_errors{$for}) {
					$$subst{class} = $$attr_ref{class} . 'error';
				}

				print_content(substitute_token($text, $tokenpos, $subst));
			} else {
				print_content($text);
			}
		} elsif ($tagname eq 'a') {
			if (   not $_do_buffer
			    and $$attr_ref{href} =~ /^\$/) {
				print_content(substitute_token($text, $tokenpos,
					{ href => substitute_vars($$attr_ref{href}) } ));
			} else {
				print_content($text);
			}
		} elsif ($tagname eq 'option') {
			if (not $_do_buffer) {
				my $subst = {};

				my $value = $$attr_ref{value};
				if (defined $value) {
				    my $new_value = substitute_vars($value);
					if ($new_value ne $value) {
						$$subst{value} = CGI->escapeHTML($new_value);
						$value = $new_value;
					}

					my $checked = $_query->param($_element_name)
						if $_element_name;
					if (defined $checked) {
						if ($checked eq $value) {
							$$subst{selected} = 1;
						} else {
							$$subst{selected} = 0;
						}
					}
				}

				if (%$subst) {
					print_content(substitute_token($text, $tokenpos, $subst));
				} else {
					print_content($text);
				}
			} else {
				print_content($text);
			}
		} elsif ($tagname eq 'div' and $$attr_ref{id} eq 'status' 
				and defined $_is_error and !$_is_error) {
			print_content(substitute_token($text, $tokenpos, { class => 'ok' }));
		} elsif ($tagname eq 'div' and defined $_is_error and $$attr_ref{id} eq 'content') {
			print_content($text);
			if($_is_error) {
				print_content(get_jquery_dialog("Fehler",get_value("status")));
			}
		} elsif (    $tagname eq 'optgroup'
		         and defined $$attr_ref{label}) {
			print_content(substitute_token($text, $tokenpos,
			              	{ label => $_d->get($$attr_ref{label}) }));
		} elsif ($tagname eq 'span') {
			if ($_do_buffer) {
				print_content($text);
			} else {
				my $subst = {};

				my $style = $$attr_ref{style};
				if (    $style
				    and my $new_style = substitute_vars($style)) {
					$$subst{style} = CGI->escapeHTML($new_style)
						if $new_style ne $style;
				}
				my $title = $$attr_ref{title};
				if (    $title
				    and my $new_title = substitute_vars($title)) {
					$$subst{title} = CGI->escapeHTML($new_title)
						if $new_title ne $title;
				}

				if (%$subst) {
					print_content(substitute_token($text, $tokenpos, $subst));
				} else {
					print_content($text);
				}
			}
		} elsif (   $tagname eq 'select'
		         or $tagname eq 'textarea') {
			if ($_do_buffer) {
				print_content($text);
			} else {
				my $subst = {};

				my $id = $$attr_ref{id};
				if (    $id
				    and my $new_id = substitute_vars($id)) {
					$new_id =~ s/[^A-Za-z0-9\-_:.]//g;
					$new_id =~ s/^([^A-Za-z])/x$1/;
					$$subst{id} = $new_id if $new_id ne $id;
				}
				my $name = $$attr_ref{name};
				if (    $name
				    and my $new_name = substitute_vars($name)) {
					if ($new_name ne $name) {
						$$subst{name} = HTML::Entities::encode_entities(CGI->escapeHTML($new_name));
						$name = $new_name;
					}
				}

				$_element_name = $name;
				if (%$subst) {
					print_content(substitute_token($text, $tokenpos, $subst));
				} else {
					print_content($text);
				}
			}
		} elsif (    $_lang
		         and $tagname eq 'meta'
		         and defined $$attr_ref{'http-equiv'}
		         and $$attr_ref{'http-equiv'} =~ /Content-Language/i) {
			print_content(
				substitute_token($text, $tokenpos,
					{ content => CGI->escapeHTML($_lang) }));
		} elsif (    $_lang
		         and $tagname eq 'html') {
			print_content(
				substitute_token($text, $tokenpos,
					{ lang => CGI->escapeHTML($_lang) }));
		} elsif ($tagname eq 'th') {
			if (not $_do_buffer) {
				my $colspan = $$attr_ref{colspan};
				if (    $colspan
				    and my $new_colspan = substitute_vars($colspan)) {
					if ($new_colspan ne $colspan) {
						print_content(substitute_token($text, $tokenpos,
						              	{ colspan => $new_colspan }));
					} else {
						print_content($text);
					}
				} else {
					print_content($text);
				}
			} else {
				print_content($text);
			}
		} else {
			print_content($text);
		}
	}
}




sub end_tag_handler {
	return if $_do_html_skip;

	my $tagname = shift;
	my $skipped_text = shift;
	my $text = shift;

	if ($_in_gettext) {
		if ($tagname eq 'gettext') {
			print_content($_d->get($_skip_buffer . $skipped_text));
			undef $_skip_buffer;
			$_in_gettext = 0;
		} else {
			$_skip_buffer .= $skipped_text . $text;
		}
	} else {
		if ($tagname eq 'title') {
			my $p = new HTML::Parser(
				api_version => 3,
				start_h => [\&start_tag_handler,
				            "tagname, attr, text, skipped_text, '',
				             tokenpos"],
				end_h => [\&end_tag_handler, "tagname, skipped_text, text"],
				comment_h => [\&comment_handler, "skipped_text, text, ''"],
				end_document_h => [\&comment_handler, "skipped_text"],
				marked_sections => 1,
				attr_encoded => 1,
			);
			$p->report_tags('gettext');

			$p->parse($skipped_text);
			$p->eof;
			print_content($text);
		} elsif ($tagname eq 'select') {
			undef $_element_name;
			print_content($skipped_text . $text);
		} elsif ($tagname eq 'textarea') {
			my $element_value = $_query->param($_element_name);
			if ($element_value) {
				print_content(CGI->escapeHTML($element_value) . $text);
			} else {
				print_content($skipped_text . $text);
			}
			undef $_element_name;
		} else {
			print_content($skipped_text . $text);
		}
	}
}




sub comment_handler {
	my $skipped_text = shift;
	my $text = shift;
	my $action = shift;

	if ($_in_gettext) {
		$_skip_buffer .= $skipped_text . $text;
		return;
	}


	if (not $_do_html_skip) {
		print_content($skipped_text);
	}

	if (not $_do_buffer) {
		if (my ($filename) = $text =~ /^<!--#include\s+file\s*=\s*"(.*)"/) {
			if (not $_do_html_skip) {
				if ($filename !~ m:(^|/)\.\./:) {
					my $p = new HTML::Parser(
						api_version => 3,
						start_h => [\&start_tag_handler,
						            "tagname, attr, text, skipped_text,
						            '$action', tokenpos"],
						end_h => [\&end_tag_handler, "tagname, skipped_text,
						          text"],
						comment_h => [\&comment_handler, "skipped_text, text,
						              '$action'"],
						end_document_h => [\&comment_handler, "skipped_text"],
						marked_sections => 1,
						attr_encoded => 1,
					);
					$p->report_tags('div', 'label', 'form', 'input',
					                'textarea', 'select', 'option', 'optgroup',
					                'title', 'html', 'meta', 'span', 'gettext');

					$p->parse_file("$Schulkonsole::Config::_templatedir/$filename")
						or die "$0: Cannot parse $Schulkonsole::Config::_templatedir/$filename: $!\n";
				} else {
					print_content($text);
				}
			}
		} elsif (my ($var) = $text =~ /^<!--#echo\s+var\s*=\s*"(.*?)"/) {
			print_content(get_value($var)) unless $_do_html_skip;
		} elsif (my ($expr) = $text =~ /^<!--#if\s+expr\s*=\s*"(.*?)"/) {
			my ($var) = $expr =~ /\$\{?(\S+)\}?/;

			if ($var =~ /^loop_(.*)$/) {
				$_var_loop = $1;
				push @_if_states, -1;
				$_do_buffer = 1;

			} else {
				my $value = get_value($var);
				push @_if_states,
					((    $value
					  and not (    ref($value) eq 'ARRAY'
					           and not @$value)) ? 1 : 0);
				$_do_html_skip = $_skip_states[-1] || ($_if_states[-1] ? 0 : 1);
				push @_skip_states, $_do_html_skip;
			}
		} elsif ($text =~ /^<!--#else/) {
			$_do_html_skip = $_skip_states[-2] || ($_if_states[-1] ? 1 : 0);
			$_skip_states[-1] = $_do_html_skip;
		} elsif ($text =~ /^<!--#endif/) {
			pop @_if_states;
			pop @_skip_states;
			$_do_html_skip = $_skip_states[-1];
		} elsif (    not $_do_html_skip
		         and my ($attrs) = $text =~ /^<!--#set\s+(.+")/) {
			my ($var, $value) =
				$attrs =~ /^var\s*=\s*"(.+?)"\s+value\s*=\s*"(.+?)"/;
			($var, $value) =
				$attrs =~ /^var\s*=\s*"(.+?)"\s+value\s*=\s*"(.+?)"/
				unless $var;


			set_value($var, $value) if $var;
		} else {
			print_content($text) unless $_do_html_skip;
		}
	} else {
		if ($text =~ /^<!--#if\s+expr\s*=\s*".*?"/) {
			push @_if_states, 1;
			print_content($text) unless $_do_html_skip;
		} elsif ($text =~ /^<!--#endif/) {
			my $if_state = pop @_if_states;
			if ($if_state == -1) {
				my $html_string = $_html_buffer;
				$_html_buffer = '';
				$_do_buffer = 0;

				if ($html_string) {
					my $var_loop = $_var_loop;
					if (my $loop_array = get_value($var_loop)) {
						die "Not a reference at: $var_loop\n"
							unless ref $loop_array;
						foreach my $var (@$loop_array) {
							set_value($var_loop, $var);
							my $p = new HTML::Parser(
								api_version => 3,
								start_h => [\&start_tag_handler,
								            "tagname, attr, text, skipped_text,
								             '$action', tokenpos"],
								end_h => [\&end_tag_handler,
								          "tagname, skipped_text, text"],
								comment_h => [\&comment_handler,
								              "skipped_text, text, '$action'"],
								end_document_h => [\&comment_handler,
								                   "skipped_text"],
								marked_sections => 1,
								attr_encoded => 1,
							);
							$p->report_tags('div', 'label', 'form', 'input',
							                'textarea',
							                'select', 'option', 'optgroup',
							                'textarea', 'title', 'html',
							                'meta', 'span', 'gettext');

							$p->parse($html_string);
							$p->eof;
						}

						set_value($var_loop, $loop_array);
					}
				}
			} elsif (not $_do_html_skip) {
				print_content($text);
			}
		} elsif (not $_do_html_skip) {
			print_content($text);
		}
	}
}




sub get_value {
	my $var = shift;

	if ($var =~ /[}\]]$/) {
		my ($varname) = $var =~ /^([^{\[]+)/;
		my @idx = $var =~ /([{\[].+?[}\]])/g;


		my $ref = $_template_vars{$varname};
		foreach my $idx (@idx) {
			if ($idx =~ /^\{(.*)\}$/) {
				$ref = $$ref{$1};
			} elsif ($idx =~ /^\[(.*)]$/) {
				$ref = $$ref[$1];
			}
		}
		return $ref;

	} else {
		return $_template_vars{$var};
	}
}




sub set_value {
	my $var = shift;
	my $value = shift;


	if ($var =~ /[}\]]$/) {
		my ($varname) = $var =~ /^([^{\[]+)/;
		my @idx = $var =~ /([{\[].+?[}\]])/g;

		my $ref = \%_template_vars;
		my $aref = $ref;
		my $ai = -1;

		$ref = $$ref{$varname};
		if ($ref) {
			$aref = $ref;

			foreach my $idx (@idx) {
				if ($idx =~ /\{(.+)\}/) {
					$ref = $$ref{$1};
				} elsif ($idx =~ /\[(.+)\]/) {
					$ref = $$ref[$1];
				} else {
					die "$0: syntax error in template variable $var\n";
				}

				if ($ref) {
					$ai++;

					if ($ai == $#idx) {
						if (ref($aref) eq 'HASH') {
							$$aref{$1} = $value;
						} else {
							$$aref[$1] = $value;
						}
						return;
					}
					$aref = $ref;
				} else {
					last;
				}
			}
		} else {
			if ($idx[0] =~ /^\{/) {
				$aref = $_template_vars{$varname} = {};
			} else {
				$aref = $_template_vars{$varname} = [];
			}
		}

		$ref = $value;
		for (my $bi = $#idx; $bi > $ai; $bi--) {
			if ($idx[$bi] =~ /\{(.+)\}/) {
				$ref = { $1 => $ref };
			} elsif ($idx[$bi] =~ /\[(.+)\]/) {
				my @a;
				$a[$1] = $ref;
				$ref = \@a;
			} else {
				die "$0: syntax error in template variable $var\n";
			}
		}

		if ($idx[$ai + 1] =~ /\{(.+)\}/) {
			$$aref{$1} = $$ref{$1};
		} elsif ($idx[$ai + 1] =~ /\[(.+)\]/) {
			$$aref[$1] = $$ref[$1];
		} else {
			die "$0: syntax error in template variable $var\n";
		}

	} else {
		$_template_vars{$var} = $value;
	}
}




sub substitute_vars {
	my $value = shift;

	my @vars = split '\$', $value;
	shift @vars;

	foreach my $var_str (@vars) {
		my ($var_name) = $var_str =~ /^\{(.+)\}/;
		my $subst;
		if ($var_name) {
			$subst = "\\\$\{$var_name\}";
		} else {
			$var_name = $var_str;
			$subst = "\\\$$var_name";
		}
		my $var_value = get_value($var_name);

		$value =~ s/$subst/$var_value/;
	}

	return $value;
}







sub print_content {
	my $content = shift;

	if ($_do_buffer) {
		$_html_buffer .= $content;
	} else {
		$_html_string .= $content;
	}
}




sub content_start_tag_handler {
	my $tagname = shift;
	my $attr = shift;
	my $skipped_text = shift;
	my $text = shift;
	my $action = shift;
	my $tokenpos = shift;

	print $skipped_text;

	if (    $$attr{href}
	    and $$attr{href} !~ m:^(http|/):) {
		my %subst;

		$subst{href} =
				$$attr{href} . '?' . CGI::Session->name() . '=' . $_session_id
			if $_no_cookies;

		if ($$attr{href} eq $action) {
			$subst{class} = $$attr{class} . 'current';
		} elsif ($$attr{href} eq $_parent_page) {
			$subst{class} = $$attr{class} . 'currentparent'
		}

		print substitute_token($text, $tokenpos, \%subst);
	} else {
		print $text;
	}
}




sub content_end_document_handler {
	my $skipped_text = shift;

	print $skipped_text;
}





1;
