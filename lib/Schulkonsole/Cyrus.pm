use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;
use Safe;


package Schulkonsole::Cyrus;

=head1 NAME

 Schulkonsole::Cyrus - interface to Cyrus commands

=head1 SYNOPSIS

 use Schulkonsole::Cyrus;

 Schulkonsole::Cyrus::quota(@users);

=head1 DESCRIPTION

Schulkonsole::Cyrus is an interface to Cyrus commands used
by schulkonsole.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	quota
);




my $input_buffer;




sub start_wrapper {
	my $app_id = shift;
	my $out = shift;
	my $in = shift;
	my $err = shift;

	my $pid = IPC::Open3::open3 $out, $in, $err,
		$Schulkonsole::Config::_wrapper_cyrus
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_cyrus, $!);

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_cyrus, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_CYRUS_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_cyrus);
		}
	}

	print $out "$app_id\n";





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
				$Schulkonsole::Config::_wrapper_cyrus, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_CYRUS_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_cyrus);
		}
	}

	close $out
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_cyrus, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_cyrus, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	undef $input_buffer;
}




=head2 Functions

=head3 C<quota(@users)>

Returns users' IMAP quotas

=head4 Parameters

=over

=item C<@users>

The usernames on the IMAP server

=back

=head4 Return value

A reference to a hash of the form C<< $username =>  quotaroot >>, where
C<$username> is the user's name on the IMAP server and
quotaroot is a hash with the quotaroot as key and a reference to the
following hash structure as a value:

=over

=item C<< quota => STORAGE => usage >>

	the quota usage

=item C<< quota => STORAGE => limit >>

	the quota limit

=item C<mbox>

	a reference to an array of the quota's mailboxes

=back

=head4 Description

Returns the quotas of the users C<@users>.

=cut

sub quota {
	my @users = @_;

	my %user_quotaroots;

	return {} unless @users;

	my $pid = start_wrapper(Schulkonsole::Config::CYRUSQUOTAAPP,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	my $ready = <SCRIPTIN>;
	print SCRIPTOUT join("\n", @users), "\n\n";

	while (<SCRIPTIN>) {
		$input_buffer .= $_;

		if (my ($limit, $usage_percent, $usage, $user)
		    	= /^\s*(\d+)\s+(\d+)\s+(\d+)\s+user\.(.+)/) {
			$user_quotaroots{$user}{"user.$user"}{quota}{STORAGE}{usage}
				= $usage;
			$user_quotaroots{$user}{"user.$user"}{quota}{STORAGE}{limit}
				= $limit;
			$user_quotaroots{$user}{"user.$user"}{mbox} = [ 'INBOX' ];
		}
	}

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);


	return \%user_quotaroots;
}






1;
