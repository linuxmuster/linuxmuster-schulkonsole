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
use Schulkonsole::Wrapper;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::DebconfError;


my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

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

