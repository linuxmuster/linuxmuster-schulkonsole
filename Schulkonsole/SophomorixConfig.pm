use strict;
use utf8;

use Schulkonsole::Config;
use Schulkonsole::Sophomorix;
use Schulkonsole::Encode;

use Sophomorix::SophomorixConfig;

use LaTeX::Encode;
use LaTeX::Decode;

package Schulkonsole::SophomorixConfig;

=head1 NAME

Schulkonsole::SophomorixConfig - interface to Sophomorix config values

=head1 SYNOPSIS

 use Schulkonsole::SophomorixConfig;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();

my $value = Schulkonsole::SophomorixConfig::read($key);

my %conf = Schulkonsole::SophomorixConfig::read(@keys);

my %conf = Schulkonsole::SophomorixConfig::read();

my $changed = Schulkonsole::SophomorixConfig::write($id,$password,$key,$value);

my %conf = (
	key1 => value1,
	key2 => value2,
	...
	keyn => valuen,
);

my %changed = Schulkonsole::SophomorixConfig::write($id,$password,%conf);

%changed = (
	key1 => 1,
	keyn => 1,
);

=head1 DESCRIPTION

Schulkonsole::SophomorixConfig is an interface to sophomorix config files.
It reads from /etc/sophomorix/user/sophomorix.conf with 
/usr/share/sophomorix/devel/sophomorix-devel.conf as fallback.
It writes to /etc/sophomorix/user/sophomorix.conf, if a value is different 
from default.

It sends SophomorixError error objects on error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	true
	false
	quotaactivated
	
	read
	write
	read_sophomorix_conf
	write_sophomorix_conf
	new_sophomorix_lines
	
	is_boolean
	is_latex
	is_string
);

=head3 Other variables

=over

=item C<$true>

Value used for 'true' in Sophomorix configuration files

=item C<$false>

Value used for 'false' in Sophomorix configuration files

=back

=cut

use vars qw($true $false);

$true = 'yes';
$false= 'no';
our $quotaactivated = (Schulkonsole::SophomorixConfig::read('use_quota') ? 1 : 0);

my %standardkeys = (
		schul_name => { type => 'Latex' },
		server_fqdn_internal_print => { type => 'String' },
		server_fqdn_external_print => { type => 'String' },
		smb_domain_print => { type => 'String' },
		moodle_url => { type => 'String' },
		admins_print => { type => 'Latex' },
		geburts_jahreszahl_start => { type => 'String' },
		geburts_jahreszahl_stop => { type => 'String' },
		vorname_nachname_tausch => { type => 'String' },
		mindest_schueler_anzahl_pro_klasse => { type => 'String' },
		maximale_schueler_anzahl_pro_klasse => { type => 'String' },
		splan_sternchenklassen_filtern => { type => 'Boolean' },
		schueler_login_nachname_zeichen => { type => 'String' },
		schueler_login_vorname_zeichen => { type => 'String' },
		schueler_zufall_passwort => { type => 'Boolean' },
		zufall_passwort_anzahl_schueler => { type => 'String' },
		schueler_per_ssh => { type => 'Boolean' },
		student_samba_pw_must_change => { type => 'Boolean' },
		lehrer_zufall_passwort => { type => 'Boolean' },
		zufall_passwort_anzahl_lehrer => { type => 'String' },
		lehrer_per_ssh => { type => 'Boolean' },
		teacher_samba_pw_must_change => { type => 'Boolean' },
		schueler_duldung_tage => { type => 'String' },
		lehrer_duldung_tage => { type => 'String' },
		schueler_deaktivierung_tage => { type => 'String' },
		lehrer_deaktivierung_tage => { type => 'String' },
		mail_aliases => { type => 'String' },
		mailquota_warnings => { type => 'Boolean' },
		mailquota_warn_percentage => { type => 'String' },
		mailquota_warn_kb => { type => 'String' },
		mailquota_warnings_root => { type => 'Boolean' },
		log_level => { type => 'String' },
		use_quota => { type => 'Boolean' },
		encoding_students => { type => 'String' },
		encoding_students_extra => { type => 'String' },
		encoding_courses_extra => { type => 'String' },
		encoding_teachers => { type => 'String' },
		lang => { type => 'String' },
		teacher_group_name => { type => 'String' },
		teachers_alias_name => { type => 'String' },
		teachers_alias_additions => { type => 'String' },
		alumni_alias_additions => { type => 'String' },
);

my %_temp = (%Conf::,%DevelConf::);
my @sophomorixkeys = keys %_temp;

=head3 C<write_sophomorix_conf($id, $password, $lines)>

Write new sophomorix.conf

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/sophomorix.conf and backups the old
file

=cut

sub write_sophomorix_conf {
	Schulkonsole::Sophomorix::write_file(@_, 2);
}




=head2 Functions

=head3 C<read($key)> | C<read(@keys)> | C<read()>

Returns the requested config value(s).

=head4 Parameters

=over

=item C<$key> | C<@keys>

The requested config key or an array of requested config keys 
(all possible config keys if no arguments are given)

=back

=head4 Return value(s)

For a single requested key the corresponding (default) value,
for an array of requested keys a hash ref containing the requested
(key,value) pairs, for an empty argument all possible config (key,value) 
pairs.

=head4 Description

Reads requested config values from sophomorix.

=cut

sub read {
	my $key = shift;
	
	if(not defined $key) {
		# alle config values
		my %ret = ();
		foreach my $k (@sophomorixkeys) {
			$ret{$k} = _read_key($k);
		}
		return \%ret;		
	} elsif(not ref($key)) {
		# return single config value
		return _read_key($key);
	} elsif(ref($key) eq 'ARRAY') {
		# return values for array of keys
		my %ret = ();
		foreach my $k (@{$key}) {
			$ret{$k} = _read_key($k);
		}
		return \%ret;
	}
	die new Schulkonsole::Error::SophomorixError(
				Schulkonsole::Error::SophomorixError::INVALID_SOPHOMORIX_CONF_KEY,
				": [$key]");
}

=head3 C<is_boolean($key)>

Check sophomorix.conf C<$key> type

=head4 Parameters

=over

=item C<$key>

The sophomorix.conf key name

=head4 Return value

Returns 1 for boolean parameter 0 otherwise

=back

=head4 Description

Checks sophomorix.conf key type and returns
check result

=cut

sub is_boolean {
	my $key = shift;
	if(not defined $key){
		return 0;
	}
	my $ref = ref($key);
	if(ref($key)){
		return 0;
	}
	if(defined $standardkeys{$key} and $standardkeys{$key}{type} eq 'Boolean'){
		return 1;
	} else {
		return 0;
	}
}

=head3 C<is_latex($key)>

Check sophomorix.conf C<$key> type

=head4 Parameters

=over

=item C<$key>

The sophomorix.conf key name

=head4 Return value

Returns 1 for latex string parameter 0 otherwise

=back

=head4 Description

Checks sophomorix.conf key type and returns
check result

=cut

sub is_latex {
	my $key = shift;
	if(not defined $key){
		return 0;
	}
	if(ref($key)){
		return 0;
	}
	if(defined $standardkeys{$key} and $standardkeys{$key}{type} eq 'Latex'){
		return 1;
	} else {
		return 0;
	}
}

=head3 C<is_string($key)>

Check sophomorix.conf C<$key> type

=head4 Parameters

=over

=item C<$key>

The sophomorix.conf key name

=head4 Return value

Returns 1 for string parameter 0 otherwise

=back

=head4 Description

Checks sophomorix.conf key type and returns
check result

=cut

sub is_string {
	my $key = shift;
	if(not defined $key){
		return 0;
	}
	if(ref($key)){
		return 0;
	}
	if(defined $standardkeys{$key} and $standardkeys{$key}{type} eq 'String'){
		return 1;
	} else {
		return 0;
	}
}


=head3 C<read_sophomorix_conf()>

Read sophomorix.conf and return (key,value) pair hash

=head4 Return value

Returns hash with key,value pairs containing sophomorix.conf
keys and corresponding values.

%{
	schul_name => 'Musterschule',
	...
}
=back

=head4 Description

Reads the file /etc/sophomorix/user/sophomorix.conf into a hash

=cut

sub read_sophomorix_conf {
	my @keys = keys %standardkeys;
	my $ret = Schulkonsole::SophomorixConfig::read(\@keys);
	return %{$ret};
}

=head3 C<new_sophomorix_lines(\%new)>

Compares hash key,value pairs to current (default) values
and returns new sophomorix.conf lines to write

=head4 Parameters

=over

=item C<\%new>

Hash ref of key,value pairs to compare to

=back

=head4 Description

Reads the current (default) values from configuration files
and compares to %new hash. Returns the lines to write to
sophomorix.conf

=cut

sub new_sophomorix_lines {
	my $new = shift;

	if (open SOPHOMORIXCONF, '<',
	         Schulkonsole::Encode::to_fs(
	         	"$DevelConf::config_pfad/sophomorix.conf")) {
		my @lines;
		my %new = %$new;

		while (my $line = <SOPHOMORIXCONF>) {
			foreach my $key (keys %new) {
				
				if ($line =~ /^\#?\s*\$$key\s*=/) {
					my $value = $new{$key};
					$line = _create_line($key,$value);
					delete $new{$key};

					last;
				}
			}
			push @lines, $line;
		}

		if (%new) {
			my @keys = keys %new;
			my $current = Schulkonsole::SophomorixConfig::read(\@keys);	
			my $line;
			foreach my $key (keys %new) {
				my $value = $new{$key};
				if($value ne $$current{$key}) {
					push @lines, "\n\n# Added by Schulkonsole\n";
					push @lines, _create_line($key,$value) . "\n";
				}
			}
		}

		return \@lines;
	} else {
		die new Schulkonsole::Error::Error(Schulkonsole::Error::Error::CANNOT_OPEN_FILE,
			"$DevelConf::config_pfad/sophomorix.conf");
	}
}

sub _create_line {
	my $key = shift;
	my $value = shift;
	my $line;
	
	$value =_to_latex($value) if is_latex($key);
	if (is_boolean($key)) {
		$line =
			"\$$key = \"" . ($value ? $true : $false) . "\";\n";
	} 
	elsif ($value =~ /^\d+$/) {
		$line = "\$$key = $value;\n";
	} else {
		$line = "\$$key = \"$value\";\n";
	}
	return $line;
}

sub _to_latex {
	my $string = shift;
	# FIXME: conversion inserts spaces
	$string = LaTeX::Encode::latex_encode($string);
	$string =~ s/@/\\@/g;
	return $string;
}

sub _from_latex {
	my $string = shift;
	# FIXME: conversion with spaces
	$string = LaTeX::Decode::latex_decode($string);
	$string =~ s/\\\@/@/g;
	# überflüssige Leerzeichen und geschweifte Klammern entfernen
	$string =~ s/([ÄÖÜäöüß])\s/$1/g;
	$string =~ s/\{\}//g;
	return $string;
}

sub _read_key {
	my $key = shift;
	# return value for $key
	my $value;
	if (defined $Conf::{$key}) {
		$value = ${$Conf::{$key}};
	} elsif (defined $DevelConf::{$key}) {
		$value = ${$DevelConf::{$key}};
	} else {
		$value = "";
	}
	if(defined $standardkeys{$key}){
		if($standardkeys{$key}{type} eq 'Boolean'){
			#FIXME compatibility:
			$value = ($value eq $true || $value eq 'on' ? 1 : 0);
		} elsif($standardkeys{$key}{type} eq 'Latex'){
			$value = _from_latex($value);
		}
	}
	return $value;	
}

1;
