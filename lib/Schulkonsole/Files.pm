use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;


package Schulkonsole::Files;

=head1 NAME

Schulkonsole::Files - interface to read and write files

=head1 SYNOPSIS

 use Schulkonsole::Files;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();


 Schulkonsole::Files::write_classrooms_file($id, $password,
 	[ 'Dining-Room', 'Hall' ]);

=head1 DESCRIPTION

Schulkonsole::Files is an interface to write files with root premissions

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	write_classrooms_file
	write_printers_file
	write_workstations_file
	import_printers
	import_workstations
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
		$Schulkonsole::Config::_wrapper_files
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_files, $!);

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_files, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_FILES_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_files);
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
				$Schulkonsole::Config::_wrapper_files, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_FILES_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_files);
		}
	}

	if ($out) {
		close $out
			or die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
				$Schulkonsole::Config::_wrapper_files, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
	}

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_files, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	undef $input_buffer;
}




=head2 Functions

=cut

#sub read_file {
#	my $id = shift;
#	my $password = shift;
#	my $file_number = shift;
#
#	my $pid = start_wrapper(Schulkonsole::Config::READFILEAPP,
#		$id, $password,
#		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
#
#	print SCRIPTOUT "$file_number\n";
#
#	my @re;
#	while (<SCRIPTIN>) {
#		push @re, $_;
#	}
#
#
#	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
#
#
#	return \@re;
#}




sub write_file {
	my $id = shift;
	my $password = shift;
	my $lines = shift;
	my $file_number = shift;

	my $pid = start_wrapper(Schulkonsole::Config::WRITEFILEAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$file_number\n", join('', @$lines);
	close SCRIPTOUT;

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
}




=head3 C<write_classrooms_file($id, $password, $lines)>

Write new classrooms file

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

Writes the file /etc/linuxmuster/classrooms

=cut

sub write_classrooms_file {
	write_file(@_, 0);
}




=head3 C<write_printers_file($id, $password, $lines)>

Write new printers file

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

Writes the file /etc/linuxmuster/printers

=cut

sub write_printers_file {
	write_file(@_, 1);
}




=head3 C<write_workstations_file($id, $password, $lines)>

Write new workstations file

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

Writes the file /etc/linuxmuster/workstations

=cut

sub write_workstations_file {
	write_file(@_, 2);
}




=head3 C<import_workstations($id, $password)>

Import workstations

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Description

This wraps the command C<import_workstations>

=cut

sub import_workstations {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::IMPORTWORKSTATIONSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head3 C<import_printers($id, $password)>

Import printers

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Description

This wraps the command C<import_printers>

=cut

sub import_printers {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::IMPORTPRINTERSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}






1;
