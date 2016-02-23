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
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::OVPNError;



my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHENTICATED_ID
      )
	unless $userdata;

my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST
      )
	unless defined $app_id;

my $app_name = $Schulkonsole::Config::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST
      )
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
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHORIZED_ID
      )
    unless $is_permission_found;


my $opts;
SWITCH: {

=head3 check

numeric constant: C<Schulkonsole::Config::OVPNCHECKAPP>

=head4 Description

invokes C<<
ovpn-client-cert.sh --check --username=<username>
>>


=head4 Parameters from standard input

none

=head3 download

numeric constant: C<Schulkonsole::Config::OVPNDOWNLOADAPP>

=head4 Description

invokes C<<
ovpn-client-cert.sh --download --username=<username>
>>


=head4 Parameters from standard input

none

=cut

(   $app_id == Schulkonsole::Config::OVPNCHECKAPP
 or $app_id == Schulkonsole::Config::OVPNDOWNLOADAPP
 or $app_id == Schulkonsole::Config::OVPNCREATEAPP) and do {
	# set ruid, so that ssh searches for .ssh/ in /root
	$< = $>;

	my $opts = "--username=\Q$$userdata{uid}\E ";
	if ($app_id == Schulkonsole::Config::OVPNCREATEAPP) {
		my $ovpn_password = <>;
		($ovpn_password) = $ovpn_password =~ /^(.{6,})$/;
		exit (  Schulkonsole::Error::OVPNError::WRAPPER_INVALID_PASSWORD
		      )
			unless $ovpn_password;

		# give password on cmdline because read does not handle pipes
		$opts .= "--create --password=$ovpn_password";
#		$opts .= '--create';

#		open PIPE, '|-', Schulkonsole::Encode::to_fs(
#		     	"$Schulkonsole::Config::_cmd_ovpn_client_cert $opts")
#			or last SWITCH;
#		print PIPE "$ovpn_password\n";
#		close PIPE;

#		last SWITCH if $?;

#		exit 0;

	} elsif ($app_id == Schulkonsole::Config::OVPNDOWNLOADAPP) {
		$opts .= '--download';
	} else {
		$opts .= '--check';
	}


	exec Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_ovpn_client_cert $opts")
		or last SWITCH;
};

}



exit -2;	# program error



