#! /usr/bin/perl

=head1 NAME

wrapper-debconf.pl - wrapper for reading debconf db

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::DEBCONFREADAPP;

 open SCRIPT, '|-', $Schulkonsole::Config::_wrapper_debconf;
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 1
 line1
 line2

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::DebconfError;


my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHENTICATED_ID)
	unless $userdata;

my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST)
	unless defined $app_id;

my $app_name = $Schulkonsole::Config::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST)
	unless defined $app_name;



my $permissions = Schulkonsole::Config::permissions_apps();
my $groups = Schulkonsole::DB::user_groups(
	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});

my $is_permission_found = 0;
foreach my $group (('ALL', keys %$groups)) {
	if ($$permissions{$group}{$app_name}) {
		$is_permission_found = 1;
		last;
	}
}
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHORIZED_ID)
	unless $is_permission_found;


my @allowed_names = ("linuxmuster-base/internsubrange","linuxmuster-base/fwconfig");

SWITCH: {
    $app_id == Schulkonsole::Config::DEBCONFREADAPP and do {
	read_debconf();
	last SWITCH;
    };

    $app_id == Schulkonsole::Config::DEBCONFREADSMTPRELAYAPP and do {
	read_smtprelay();
	last SWITCH;
    };

};


=head3 read_debconf

=head4 Parameters from standard input

=over

=item section

section to read debconf value from

=item name

name of debconf value to read

=back

=cut

sub read_debconf() {
	my $section = <>;
	($section) = $section =~ /^([a-z\-]+)$/;
	exit (  Schulkonsole::Error::DebconfError::WRAPPER_INVALID_SECTION)
		unless defined $section;

	my $name = <>;
	($name) = $name =~ /^([a-z\-]+)$/;
	exit (  Schulkonsole::Error::DebconfError::WRAPPER_INVALID_NAME)
		unless defined $name;

	exit (  Schulkonsole::Error::DebconfError::WRAPPER_INVALID_REQUEST)
		unless /$section\/$name/ ~~ @allowed_names;

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	my $command = '/bin/bash -c "echo get '.$section.'/'.$name.' | debconf-communicate -fnoninteractive" |';
	open(SCRIPTIN, $command) or
	exit (  Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	my $line;
	while(<SCRIPTIN>) {
	    ($line) = $_ =~ /^(.*?)$/;
	    print "$line\n" if defined $line;
	}
	close(SCRIPTIN) or 
	exit (  Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	exit 0;
}


=head3 read_smtprelay

=back

=cut

sub read_smtprelay() {

	$< = $>;
	$) = 0;
	$( = $);
	umask(022);

	my $command = '/bin/bash -c "echo get linuxmuster-base/smtprelay | debconf-communicate -fnoninteractive" |';
	open(SCRIPTIN, $command) or
	exit (  Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED);

	my $line;
	while(<SCRIPTIN>) {
	    ($line) = $_ =~ /^(.*?)$/;
	    print "$line\n" if defined $line;
	}
	close(SCRIPTIN)
		or exit ( Schulkonsole::Error::Error::WRAPPER_SCRIPT_EXEC_FAILED );

	exit 0;
};
exit -2;	# program error

