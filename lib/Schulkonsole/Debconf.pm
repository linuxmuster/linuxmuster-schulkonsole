use strict;
use utf8;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Error::Debconf;
use Schulkonsole::Config;


package Schulkonsole::Debconf;

=head1 NAME

Schulkonsole::Debconf - interface to read debconf section/values

=head1 SYNOPSIS

 use Schulkonsole::Debconf;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();


 Schulkonsole::Debconf::read($id, $password,
 	'linuxmuster-base','internsubmask');

 Schulkonsole::Debconf::read_smtprelay($id, $password);

=head1 DESCRIPTION

Schulkonsole::Debconf is an interface to read debconf values with root premissions

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	read
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
		$Schulkonsole::Config::_wrapper_debconf
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_debconf, $!);

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
				$Schulkonsole::Config::_wrapper_debconf, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::Files::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_debconf);
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
				$Schulkonsole::Config::_wrapper_debconf, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::Files::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_debconf);
		}
	}

	if ($out) {
		close $out
			or die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
				$Schulkonsole::Config::_wrapper_debconf, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
	}

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_debconf, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	undef $input_buffer;
}




=head2 Functions

=head3 C<read($id, $password, $section, $name)>

Read and return a debconf value.

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$section>

The debconf section to read the value from.

=item C<$name>

The debconf name for the variable to read the value from.

=head4 Output

Return the value.

=back

=head4 Description

Read the value C<$name> specified in C<$section> from the
debconf database.

=cut

sub read {
	my $id = shift;
	my $password = shift;
	my $section = shift;
	my $name = shift;

	my $pid = start_wrapper(Schulkonsole::Config::DEBCONFREADAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$section\n$name\n";
	close SCRIPTOUT;

	my $ret;
	my $value;
	while (<SCRIPTIN>) {
		($ret,$value) = $_ =~ /^(\d+)\s+([a-zA-Z\d\-]+)$/;
		next if not defined $ret;
		die new Schulkonsole::Error(
			Schulkonsole::Error::Debconf::WRAPPER_INVALID_REQUEST,
			$Schulkonsole::Config::_wrapper_debconf, $!,
			    "debconf-communicate error $ret")
			unless $ret == 0;
	}

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);

	return $value;
}


=head3 C<read_smtprelay($id, $password)>

Read and return the debconf value linuxmuster-base/smtprelay.

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=head4 Output

Return the linuxmuster-base/smtprelay value.

=back

=head4 Description

Read the value C<linuxmuster-base/smtprelay> from the
debconf database.

=cut

sub read_smtprelay {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::DEBCONFREADSMTPRELAYAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	my $ret;
	my $value;
	while (<SCRIPTIN>) {
		($ret,$value) = $_ =~ /^(\d+)\s+([a-zA-Z\d\-\.]+)$/;
		next if not defined $ret;
		die new Schulkonsole::Error(
			Schulkonsole::Error::Debconf::WRAPPER_INVALID_REQUEST,
			$Schulkonsole::Config::_wrapper_debconf, $!,
			    "debconf-communicate error $ret")
			unless $ret == 0 || $ret == 10;
	}

	stop_wrapper($pid, undef, \*SCRIPTIN, \*SCRIPTIN);
	if($ret == 0) {
	    return $value;
	} else {
	    return "";
	}
}



1;
