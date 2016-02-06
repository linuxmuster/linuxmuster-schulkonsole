use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error::Error;
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




my $input_buffer;
sub buffer_input {
	my $in = shift;

	while (<$in>) {
		$input_buffer .= $_;
	}
}




sub start_wrapper {
	my $app_id = shift;
	my $id = shift;
	my $password = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $pid = IPC::Open3::open3 $out, $in, $err,
		$Schulkonsole::Config::_wrapper_ovpn
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_ovpn, $!);

	binmode $out, ':utf8';
	binmode $in, ':utf8';
	binmode $err, ':utf8';


	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_ovpn, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::OVPN::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_ovpn);
		}
	}

	print $out "$id\n$password\n$app_id\n";





	return $pid;
}




sub stop_wrapper {
	my $pid = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $return_code = 0;

	my $re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
		$return_code = ($? >> 8);

		# ovpn-client-cert.sh returns 1 if there is no certificate (no error)
		if ($return_code != 1) {
			my $error = $return_code - 256;
			if ($error < -127) {
				die new Schulkonsole::Error(
					Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
					$Schulkonsole::Config::_wrapper_ovpn, $!,
					($input_buffer ? "Output: $input_buffer" : 'No Output'));
			} else {
				die new Schulkonsole::Error(
					Schulkonsole::Error::OVPN::WRAPPER_ERROR_BASE + $error,
					$Schulkonsole::Config::_wrapper_ovpn);
			}
		}
	}

	close $out
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_ovpn, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_ovpn, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));
	
	undef $input_buffer;

	return $return_code;
}




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

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::OVPNCHECKAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	buffer_input(\*SCRIPTIN);

	my $not_re = stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);


	return not $not_re;
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

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::OVPNCREATEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$ovpn_password\n";

	buffer_input(\*SCRIPTIN);

	my $not_re = stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);


	return not $not_re;
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

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::OVPNDOWNLOADAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	buffer_input(\*SCRIPTIN);

	my $not_re = stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);


	return not $not_re;
}






1;
