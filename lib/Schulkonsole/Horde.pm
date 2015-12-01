use strict;
use open ':utf8';
use IPC::Open3;
use POSIX 'sys_wait_h';
use Net::IMAP::Simple;
use Schulkonsole::Config;
use Schulkonsole::Error;

=head1 NAME

Schulkonsole::Horde - get/set mail forwards

=cut

package Schulkonsole::Horde;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	get_mailforwards
	set_mailforwards
	remove_mailforwards
);


=head3 C<get_mailforwards($user,$password)>

=cut

sub get_mailforwards {
	my $uid = shift;
        my $password = shift;

        my $command = $Schulkonsole::Config::_cmd_horde_mail;
        $command .= " --user=$uid --password=$password --get-forwards";

	my $pid = IPC::Open3::open3 \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN,
		$command
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_cmd_horde_mail, $!);
	
	binmode SCRIPTIN, ':utf8';
	binmode SCRIPTOUT, ':utf8';

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_cmd_horde_mail, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::User::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_cmd_horde_mail);
		}
	}

	close SCRIPTOUT
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_cmd_horde_mail, $!);

	my $mailforwards;
        my $mailkeep;
        while (<SCRIPTIN>) {
                chomp;
                next unless $_ =~ m/^$uid;.*/;
		my @line = split ";";
		
                $mailforwards = $line[1];
                if( defined $line[2]) {
                    $mailkeep = 1;
                } else {
                    $mailkeep = 0;
                }
	}

	$re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_cmd_horde_mail, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::User::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_cmd_horde_mail);
		}
	}

	close SCRIPTIN
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_cmd_horde_mail, $!);

	return ($mailforwards,$mailkeep);
}











=head3 C<set_mailforwards($user,$password,$mailforwards,$mailkeep)>

=cut

sub set_mailforwards {
	my $uid = shift;
        my $password = shift;
        my $mailforwards = shift;
        my $mailkeep = shift;
        
        my $command = $Schulkonsole::Config::_cmd_horde_mail;
        $command .= " --user=$uid --password=$password --set-forwards=$mailforwards";
        if ($mailkeep) {
            $command .= " --keep";
        }

	my $pid = IPC::Open3::open3 \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN,
		$command
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_cmd_horde_mail, $!);
	
	binmode SCRIPTIN, ':utf8';
	binmode SCRIPTOUT, ':utf8';

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_cmd_horde_mail, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::User::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_cmd_horde_mail);
		}
	}

	close SCRIPTOUT
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_cmd_horde_mail, $!);

	$re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_cmd_horde_mail, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::User::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_cmd_horde_mail);
		}
	}

	close SCRIPTIN
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_cmd_horde_mail, $!);

	return 0;
}










=head3 C<remove_mailforwards($user,$password)>

=cut

sub remove_mailforwards {
	my $uid = shift;
        my $password = shift;
        
        my $command = $Schulkonsole::Config::_cmd_horde_mail;
        $command .= " --user=$uid --password=$password --remove-forwards";

	my $pid = IPC::Open3::open3 \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN,
		$command
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_cmd_horde_mail, $!);
	
	binmode SCRIPTIN, ':utf8';
	binmode SCRIPTOUT, ':utf8';

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_cmd_horde_mail, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::User::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_cmd_horde_mail);
		}
	}

	close SCRIPTOUT
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_cmd_horde_mail, $!);

	$re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
	    my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_cmd_horde_mail, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::User::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_cmd_horde_mail);
		}
	}

	close SCRIPTIN
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_cmd_horde_mail, $!);

	return 0;
}










1;
