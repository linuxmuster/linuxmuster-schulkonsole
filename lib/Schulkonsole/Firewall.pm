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
 if ($$hosts{'00:00:39:F2:C9:A1'}) {
 	print "00:00:39:F2:C9:A1 is blocked\n";
 }

 $hosts = Schulkonsole::Firewall::blocked_hosts_intranet();
 $hosts = Schulkonsole::Firewall::unfiltered_hosts();

 my @macs = ('00:00:39:F2:C9:A1', '00:00:39:F2:C9:A2');
 my @hosts = ('10.1.15.1', '10.1.15.2');
 Schulkonsole::Firewall::internet_on($id, $password, @macs);
 Schulkonsole::Firewall::internet_off($id, $password, @macs);
 Schulkonsole::Firewall::intranet_on($id, $password, @macs);
 Schulkonsole::Firewall::intranet_off($id, $password, @macs);
 Schulkonsole::Firewall::urlfilter_on($id, $password, @hosts);
 Schulkonsole::Firewall::urlfilter_off($id, $password, @hosts);

 my $room = 'Dining-Room';
 Schulkonsole::Firewall::all_on($id, $password, $room);

 my $time = $^T + 3600;
 Schulkonsole::Firewall::all_on_at($id, $password, $room, $time);

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
	urlfilter_on
	urlfilter_off
	all_on
	all_on_at
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
				Schulkonsole::Error::WRAPPER_FIREWALL_ERROR_BASE + $error,
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

	my $re = waitpid $pid, 0;
	if (    ($re == $pid or $re == -1)
	    and $?) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
				$Schulkonsole::Config::_wrapper_firewall, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_FIREWALL_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_firewall);
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
}




=head2 Functions

=head3 C<internet_on($id, $password, @macs)>

Un-block hosts' access to the internet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@macs>

The MAC-adresses of the workstations

=back

=head3 Description

This wraps the command
C<internet_on_off.sh --trigger=on --maclist=mac1,mac2,...>, where
C<mac1,mac2,...> are the MACs in C<@macs>.

=cut

sub internet_on {
	my $id = shift;
	my $password = shift;
	my @macs = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTERNETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set macs in list to on
	print SCRIPTOUT "1\n", join("\n", @macs), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<internet_off($id, $password, @macs)>

Block hosts' access to the internet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@macs>

The MAC-adresses of the workstations

=back

=head3 Description

This wraps the command
C<internet_on_off.sh --trigger=off --maclist=mac1,mac2,...>, where
C<mac1,mac2,...> are the MACs in C<@macs>.

=cut

sub internet_off {
	my $id = shift;
	my $password = shift;
	my @macs = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTERNETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set macs in list to off
	print SCRIPTOUT "0\n", join("\n", @macs), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<intranet_on($id, $password, @macs)>

Un-block hosts' access to the intranet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@macs>

The MAC-adresses of the workstations

=back

=head3 Description

This wraps the command
C<intranet_on_off.sh --trigger=on --maclist=mac1,mac2,...>, where
C<mac1,mac2,...> are the MACs in C<@macs>.

=cut

sub intranet_on {
	my $id = shift;
	my $password = shift;
	my @macs = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTRANETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set macs in list to on
	print SCRIPTOUT "1\n", join("\n", @macs), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<intranet_off($id, $password, @macs)>

Block hosts' access to the intranet

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@macs>

The MAC-adresses of the workstations

=back

=head3 Description

This wraps the command
C<intranet_on_off.sh --trigger=off --maclist=mac1,mac2,...>, where
C<mac1,mac2,...> are the MACs in C<@macs>.

=cut

sub intranet_off {
	my $id = shift;
	my $password = shift;
	my @macs = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::INTRANETONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set macs in list to off
	print SCRIPTOUT "0\n", join("\n", @macs), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
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





sub read_mac_file {
	my $filename = shift;

	my %macs;


	if (not open MACS, "<$filename") {
		warn "$0: Cannot open $filename";
		return {};
	}

	while (<MACS>) {
		chomp;
		$macs{$_} = 1;
	}

	close MACS;

	return \%macs;
}




=head3 C<blocked_hosts_internet()>

Returns which hosts' access to the internet is blocked

=head4 Return value

A hash with blocked host's MAC-address as key and C<1> as value.

=cut

sub blocked_hosts_internet {
	return read_mac_file($Schulkonsole::Config::_blocked_hosts_internet_file);
}




=head3 C<blocked_hosts_intranet()>

Returns which hosts' access to the intranet is blocked

=head4 Return value

A hash with blocked host's MAC-address as key and C<1> as value.

=cut

sub blocked_hosts_intranet {
	return read_mac_file($Schulkonsole::Config::_blocked_hosts_intranet_file);
}




=head3 C<unfiltered_hosts()>

Returns which hosts' access to URLs is filtered

=head4 Return value

A hash with an unfiltered host's MAC-address as key and C<1> as value.

=cut

sub unfiltered_hosts {
	return read_mac_file($Schulkonsole::Config::_unfiltered_hosts_file);
}






1;
