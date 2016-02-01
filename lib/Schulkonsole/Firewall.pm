#
# $Id$
#
use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;


package Schulkonsole::Firewall;

=head1 NAME

Schulkonsole::Firewall - interface to Linuxmusterloesung Firewall commands

=head1 SYNOPSIS

 use Schulkonsole::Firewall;

 my $hosts = Schulkonsole::Firewall::blocked_hosts_internet();
 if ($$hosts{'10.16.2.1'}) {
 	print "10.16.2.1 is blocked\n";
 }

 $hosts = Schulkonsole::Firewall::blocked_hosts_intranet();
 $hosts = Schulkonsole::Firewall::unfiltered_hosts();

 my @hosts = ('10.1.15.1', '10.1.15.2');
 Schulkonsole::Firewall::internet_on($id, $password, @hosts);
 Schulkonsole::Firewall::internet_off($id, $password, @hosts);
 Schulkonsole::Firewall::intranet_on($id, $password, @hosts);
 Schulkonsole::Firewall::intranet_off($id, $password, @hosts);
 Schulkonsole::Firewall::urlfilter_on($id, $password, @hosts);
 Schulkonsole::Firewall::urlfilter_off($id, $password, @hosts);

 my $room = 'Dining-Room';
 Schulkonsole::Firewall::all_on($id, $password, $room);

 my $time = $^T + 3600;
 Schulkonsole::Firewall::all_on_at($id, $password, $room, $time);


 Schulkonsole::Firewall::rooms_reset_all($id, $password);

=head1 DESCRIPTION

Schulkonsole::Firewall is an interface to the Linuxmusterloesung Firewall
commands used by schulkonsole. It also provides functions related to
these commands.
Namely commands to get lists of currently blocked and filtered hosts.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	blocked_hosts_internet
	blocked_hosts_intranet
	unfiltered_hosts
	internet_on
	internet_off
	intranet_on
	intranet_off
	update_logins
	urlfilter_check
	urlfilter_on
	urlfilter_off
	all_on
	all_on_at
	rooms_reset_all
	rooms_reset
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
		$Schulkonsole::Config::_wrapper_firewall
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_firewall, $!);

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
				$Schulkonsole::Config::_wrapper_firewall, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::Firewall::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_firewall);
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
	my $one_is_good = shift;

	my $rv = undef;


	my $re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
		my $error = ($? >> 8) - 256;
		if (    $one_is_good
		    and $error == -255) {
			$rv = 1;
		} elsif ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_wrapper_firewall, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::Firewall::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_firewall,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		}
	}

	close $out
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_firewall, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_firewall, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));
	
	undef $input_buffer;


	return $rv;
}




=head2 Functions

=head3 C<internet_on($id, $password, @hosts)>

Unblock hosts' access to the internet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@hosts>

The ip adresses of the workstations

=back

=head3 Description

This wraps the command
C<internet_on_off.sh --trigger=on --hostlist=ip1,ip2,...>, where
C<ip1,ip2,...> are the IPs in C<@hosts>.

=cut

sub internet_on {
	my $id = shift;
	my $password = shift;
	my @hosts = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTERNETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set hosts in list to on
	print SCRIPTOUT "1\n", join("\n", @hosts), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<internet_off($id, $password, @hosts)>

Block hosts' access to the internet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@hosts>

The ip adresses of the workstations

=back

=head3 Description

This wraps the command
C<internet_on_off.sh --trigger=off --hostlist=ip1,ip2,...>, where
C<ip1,ip2,...> are the IPs in C<@hosts>.

=cut

sub internet_off {
	my $id = shift;
	my $password = shift;
	my @hosts = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTERNETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set hosts in list to off
	print SCRIPTOUT "0\n", join("\n", @hosts), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<intranet_on($id, $password, @hosts)>

Un-block hosts' access to the intranet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@hosts>

The IP adresses of the workstations

=back

=head3 Description

This wraps the command
C<intranet_on_off.sh --trigger=on --hostlist=host1,host2,...>, where
C<host1,host2,...> are the IPs in C<@hosts>.

=cut

sub intranet_on {
	my $id = shift;
	my $password = shift;
	my @hosts = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTRANETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set hosts in list to on
	print SCRIPTOUT "1\n", join("\n", @hosts), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<intranet_off($id, $password, @hosts)>

Block hosts' access to the intranet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@hosts>

The IP adresses of the workstations

=back

=head3 Description

This wraps the command
C<intranet_on_off.sh --trigger=off --hostlist=host1,host2,...>, where
C<host1,host2,...> are the IPs in C<@hosts>.

=cut

sub intranet_off {
	my $id = shift;
	my $password = shift;
	my @hosts = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTRANETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set hosts in list to off
	print SCRIPTOUT "0\n", join("\n", @hosts), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<update_logins($id, $password, $room)>

Updates login information for a room

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$room>

The current room

=back

=head4 Return value

True if successfull, false otherwise

=head3 Description

This wraps the command C<update-logins.sh>.

=cut

sub update_logins {
	my $id = shift;
	my $password = shift;
	my $room = shift;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::UPDATELOGINSAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$room\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<urlfilter_check($id, $password)>

Checks if URL-filter is active

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head4 Return value

True if active, false otherwise

=head3 Description

This wraps the command C<check_urlfilter.sh>.

=cut

sub urlfilter_check {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::URLFILTERCHECKAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	buffer_input(\*SCRIPTIN);


	return not stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN, 1);
}




=head3 C<urlfilter_on($id, $password, @hosts)>

Turns on filtering of URLs for certain hosts

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@hosts>

The hostnames of the workstations

=back

=head3 Description

This wraps the command
C<urlfilter_on_off.sh --trigger=on --hostlist=host1,host2,...>, where
C<host1,host2,...> are the hostnames in C<@hosts>.

=cut

sub urlfilter_on {
	my $id = shift;
	my $password = shift;
	my @hosts = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::URLFILTERONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set hosts in list to on
	print SCRIPTOUT "1\n", join("\n", @hosts), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<urlfilter_off($id, $password, @hosts)>

Turns off filtering of URLs for certain hosts

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@hosts>

The hostnames of the workstations

=back

=head3 Description

This wraps the command
C<urlfilter_on_off.sh --trigger=off --hostlist=host1,host2,...>, where
C<host1,host2,...> are the hostnames in C<@hosts>.

=cut

sub urlfilter_off {
	my $id = shift;
	my $password = shift;
	my @hosts = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::URLFILTERONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set hosts in list to off
	print SCRIPTOUT "0\n", join("\n", @hosts), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<all_on($id, $password, $room)>

Resets system configuration

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$room>

The room corresponding to the command as defined in /etc/linuxmuster/classrooms

=back

=head3 Description

Resets all configuration changes to values stored in the
Schulkonsole::RoomSession of C<$room>.
This includes changes done with the functions in Schulkonsole::Firewall,
Schulkonsole::Sophomorix and Schulkonsole::Printer.

=cut

sub all_on {
	my $id = shift;
	my $password = shift;
	my $room = shift;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::ALLONAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$room\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<all_on_at($id, $password, $room, $time)>

Will reset system configuration at a given time

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$room>

The room corresponding to the command as defined in /etc/linuxmuster/classrooms

=item C<$time>

The time given in seconds since beginning of the epoch (1970-01-01 00:00:00)

=back

=head3 Description

Resets all configuration changes to values stored in the
Schulkonsole::RoomSession of C<$room> at time C<$time>.
This includes changes done with the functions in Schulkonsole::Firewall,
Schulkonsole::Sophomorix and Schulkonsole::Printer.

=cut

sub all_on_at {
	my $id = shift;
	my $password = shift;
	my $room = shift;
	my $time = shift;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::ALLONATAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$room\n$time\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}





sub read_hosts_file {
	my $filename = shift;

	my %hosts;


	if (not open HOSTS, "<$filename") {
		warn "$0: Cannot open $filename";
		return {};
	}

	while (<HOSTS>) {
		chomp;
		$hosts{$_} = 1;
	}

	close HOSTS;

	return \%hosts;
}




=head3 C<blocked_hosts_internet()>

Returns which hosts' access to the internet is blocked

=head4 Return value

A hash with blocked host's IP address as key and C<1> as value.

=cut

sub blocked_hosts_internet {
	return read_hosts_file($Schulkonsole::Config::_blocked_hosts_internet_file);
}




=head3 C<blocked_hosts_intranet()>

Returns which hosts' access to the intranet is blocked

=head4 Return value

A hash with blocked host's IP address as key and C<1> as value.

=cut

sub blocked_hosts_intranet {
	return read_hosts_file($Schulkonsole::Config::_blocked_hosts_intranet_file);
}




=head3 C<unfiltered_hosts()>

Returns which hosts' access to URLs is filtered

=head4 Return value

A hash with an unfiltered host's IP address as key and C<1> as value.

=cut

sub unfiltered_hosts {
	return read_hosts_file($Schulkonsole::Config::_unfiltered_hosts_file);
}




=head3 C<rooms_reset_all($id, $password)>

Resets firewall settings of all workstations

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

Invokes C<linuxmuster-reset --all>

=cut

sub rooms_reset_all {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::ROOMSRESETAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}






=head3 C<rooms_reset($id, $password, $rooms, $hosts)>

Resets firewall settings selected workstations

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$rooms>

Reference to an array of rooms

=item C<$hosts>

Reference to an array of hosts

=back

=head3 Description

Invokes C<linuxmuster-reset --room=ROOM> for each C<ROOM> in C<$rooms>,
and C<linuxmuster-reset --host=HOST> for each C<HOST> in C<$hosts>.

=cut

sub rooms_reset {
	my $id = shift;
	my $password = shift;
	my $rooms = shift;
	my $hosts = shift;

	my $pid = start_wrapper(Schulkonsole::Config::ROOMSRESETAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n", join("\n", @$rooms, ''), "\n",
	                       join("\n", @$hosts, ''), "\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}







1;
