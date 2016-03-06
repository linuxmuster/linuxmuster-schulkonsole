#! /usr/bin/perl

=head1 NAME

wrapper-ovpn.pl - wrapper for configuration of ovpn

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::INTERNETONOFFAPP;

 my $ovpn_username = 'testuser';

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_ovpn";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 $ovpn_username

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
use Schulkonsole::Error::OVPNError;


my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

my $opts;
SWITCH: {
	$app_id == Schulkonsole::Config::OVPNCHECKAPP and do {
		check();
		last SWITCH;
	};
	 $app_id == Schulkonsole::Config::OVPNDOWNLOADAPP and do {
	 	download();
	 	last SWITCH;
	 };
	 $app_id == Schulkonsole::Config::OVPNCREATEAPP and do {
	 	create();
	 	last SWITCH;
	 };
};
	 
exit -2;	# program error

=head3 check

numeric constant: C<Schulkonsole::Config::OVPNCHECKAPP>

=head4 Description

invokes C<<
ovpn-client-cert.sh --check --username=<username>
>>

=head4 Parameters from standard input

none

=cut

sub check(){
	# set ruid, so that ssh searches for .ssh/ in /root
	$< = $>;
	umask(022);

	my $opts = "--username=\Q$$userdata{uid}\E ";
	$opts .= '--check';

	my $ret = system(Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_ovpn_client_cert $opts >/dev/null 2>/dev/null"));
	print ($ret? "0\n" : "1\n");

	exit(0);
}

=head3 create

numeric constant: C<Schulkonsole::Config::OVPNCREATEAPP>

=head4 Description

invokes C<<
ovpn-client-cert.sh --create --username=<username> --password=<password>
>>


=head4 Parameters from standard input

none

=cut

sub create(){
	# set ruid, so that ssh searches for .ssh/ in /root
	$< = $>;
	umask(022);

	my $opts = "--username=\Q$$userdata{uid}\E ";
	my $ovpn_password = <>;
	($ovpn_password) = $ovpn_password =~ /^(.{6,})$/;
	exit (  Schulkonsole::Error::OVPNError::WRAPPER_INVALID_PASSWORD )
		unless $ovpn_password;

	# give password on cmdline because read does not handle pipes
	$opts .= "--create --password=\Q${ovpn_password}\E";

	my $ret = system(Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_ovpn_client_cert $opts >/dev/null 2>/dev/null"));
	exit ( Schulkonsole::Error::OVPNError::WRAPPER_INVALID_PASSWORD )
		if $ret == 2;
	print ($ret? "0\n" : "1\n");

	exit 0;
}

=head3 download

numeric constant: C<Schulkonsole::Config::OVPNDOWNLOADAPP>

=head4 Description

invokes C<<
ovpn-client-cert.sh --download --username=<username>
>>


=head4 Parameters from standard input

none

=cut

sub download(){
	# set ruid, so that ssh searches for .ssh/ in /root
	$< = $>;
	umask(022);

	my $opts = "--username=\Q$$userdata{uid}\E ";
	$opts .= '--download';

	my $ret = system(Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_ovpn_client_cert $opts >/dev/null 2>/dev/null"));
	print ($ret? "0\n" : "1\n");

	exit( 0 );
}


