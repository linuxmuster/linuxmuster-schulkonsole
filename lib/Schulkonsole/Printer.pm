use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;

=head1 NAME

Schulkonsole::Printer - access printing system

=cut

package Schulkonsole::Printer;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	printer_info
	printer_on
	printer_off
	printer_deny
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
		$Schulkonsole::Config::_wrapper_printer
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_printer, $!);

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_printer, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_PRINTER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_printer);
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

	my $re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_wrapper_printer, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_PRINTER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_printer);
		}
	}

	close $out
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_printer, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_printer, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	undef $input_buffer;
}




=head2 C<printer_info($id, $password)>

Return information about configured printers

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Return value

A reference to a hash with printer names as keys and a reference to a
hash with the information as values. The information for the keys
State, StateMessage, Info, Location, and Accepting are scalar values.
The values for AllowUser and DenyUser are references to hashes with
usernames as keys.

=head3 Description

Read the file printers.conf and return the information.

=cut

sub printer_info {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::PRINTERINFOAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	my $in;
	while (<SCRIPTIN>) {
		$in .= $_;
	}

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head2 C<printer_on($id, $password, $printers)>

Turn accepting of print jobs on

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$printers>

A reference to an array of printers

=back

=head3 Description

This wraps the command C</usr/sbin/accept printer1 printer2,...>
where C<printer1>, C<printer2> are the printers in C<$printers>.

=cut

sub printer_on {
	my $id = shift;
	my $password = shift;
	my $printers = shift;

	my $pid = start_wrapper(Schulkonsole::Config::PRINTERONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n",
		join("\n", @$printers), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head2 C<printer_off($id, $password, $printers)>

Turn accepting of print jobs off

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$printers>

A reference to an array of printers

=back

=head3 Description

This wraps the command C</usr/sbin/reject printer1 printer2,...>
where C<printer1>, C<printer2> are the printers in C<$printers>.

=cut

sub printer_off {
	my $id = shift;
	my $password = shift;
	my $printers = shift;

	my $pid = start_wrapper(Schulkonsole::Config::PRINTERONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n",
		join("\n", @$printers), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}





=head2 C<printer_deny($id, $password, $printer_users)>

Deny users access to printers

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$printer_users>

A reference to hash with printer names as keys and a reference to an array
of users to be denied access to this printer as value

=back

=head3 Description

This wraps commands C</usr/sbin/lpadmin -pprinter -u deny:user1,user2,...>
for each printer in C<keys %$printer_users> and C<user1>, C<user2> the
users in C<$$printer_users{$printer}>.

=cut

sub printer_deny {
	my $id = shift;
	my $password = shift;
	my $printer_users = shift;

	my $pid = start_wrapper(Schulkonsole::Config::PRINTERALLOWDENYAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	foreach my $printer (keys %$printer_users) {
		print SCRIPTOUT "$printer\n",
			join("\n", @{ $$printer_users{$printer} }, ''), "\n";
	}
	print SCRIPTOUT "\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}





1;
