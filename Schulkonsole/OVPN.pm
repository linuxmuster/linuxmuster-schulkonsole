use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::OVPNError;
use Schulkonsole::Config;


package Schulkonsole::OVPN;

=head1 NAME

Schulkonsole::OVPN - interface to Linuxmusterloesung OpenVPN commands

=head1 SYNOPSIS

 use Schulkonsole::OVPN;

 my $re = Schulkonsole::OVPN::check($id, $password);

 if ($re) {
 	print "User has no OpenVPN certificate\n";

	my $password = 'secret'; # > 6 characters
 	Schulkonsole::OVPN::create($id, $password, $password);
 } else {
	 Schulkonsole::OVPN::download($id, $password);
 }

=head1 DESCRIPTION

Schulkonsole::OVPN is an interface to the Linuxmusterloesung OpenVPN
commands used by schulkonsole.

If a wrapper command fails, it usually dies with a Schulkonsole::Error::Error or subclass.
The output of the failed command is stored in the Schulkonsole::Error::Error subclass.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	check
	create
	download
);

my $wrapcmd = $Schulkonsole::Config::_wrapper_ovpn;
my $errorclass = "Schulkonsole::Error::OVPNError";


=head2 Functions

=head3 C<check($id, $password)>

Check if an OpenVPN certificate exists

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

This wraps the command
C<ovpn-client-cert.sh --check --username=uid>,
where uid is the UID of the user with the ID C<$id>

=cut

sub check {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::OVPNCHECKAPP,
		$id, $password);
	chomp $in;
	return ($in == 0 ? 0 : 1); 
}





=head3 C<create($id, $password, $ovpn_password)>

Create an OpenVPN certificate

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$ovpn_password>

The password for the certificate

=back

=head3 Description

This wraps the command
C<ovpn-client-cert.sh --create --username=uid>,
where uid is the UID of the user with the ID C<$id>

=cut

sub create {
	my $id = shift;
	my $password = shift;
	my $ovpn_password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::OVPNCREATEAPP,
		$id, $password, "$ovpn_password\n");
	chomp $in;
	return ($in == 0? 0: 1);
}





=head3 C<download($id, $password)>

Download an existing OpenVPN certificate

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

This wraps the command
C<ovpn-client-cert.sh --download --username=uid>,
where uid is the UID of the user with the ID C<$id>

=cut

sub download {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::OVPNDOWNLOADAPP,
		$id, $password);
	chomp $in;
	return ($in == 0? 0 : 1);
}






1;
