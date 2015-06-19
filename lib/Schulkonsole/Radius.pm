#
# $Id$
#
use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;

package Schulkonsole::Radius;

=head1 NAME

Schulkonsole::Radius - interface to Linuxmusterloesung Radius commands

=head1 SYNOPSIS

 use Schulkonsole::Radius;

 my $groups = Schulkonsole::Radius::allowed_groups_wlan();
 if ($$groups{'07a'}) {
 	print "07a is allowed\n";
 }

 my @groups = ('07a', 'p_7in1');
 Schulkonsole::Radius::wlan_on($id, $password, @groups);
 Schulkonsole::Radius::wlan_off($id, $password, @groups);

 Schulkonsole::Radius::wlan_on_at($id, $password, @groups, @time);
 Schulkonsole::Radius::groups_reset_all($id, $password);

=head1 DESCRIPTION

Schulkonsole::Radius is an interface to the Linuxmusterloesung Radius
commands used by schulkonsole. It also provides functions related to
these commands.
Namely commands to get lists of currently allowed groups.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	allowed_groups_wlan
	group_defaults
	wlan_on
	wlan_off
	wlan_reset_at
	wlan_reset_all
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
		$Schulkonsole::Config::_wrapper_radius
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_radius, $!);

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
				$Schulkonsole::Config::_wrapper_radius, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::Radius::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_radius);
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
				$Schulkonsole::Config::_wrapper_radius, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::Radius::WRAPPER_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_radius,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		}
	}

	close $out
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_radius, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_radius, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));
	
	undef $input_buffer;


	return $rv;
}




=head2 Functions

=head3 C<wlan_on($id, $password, @groups)>

Allow groups' access to the wlan

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@groups>

The groups to allow wlan access

=back

=head3 Description

This wraps the command
C<wlan_on_off.sh --trigger=on --grouplist=group1,group2,... , where
C<group1,group2,...> are the groups in C<@groups>.

=cut

sub wlan_on {
	my $id = shift;
	my $password = shift;
	my @groups = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::WLANONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set groups in list to on
	print SCRIPTOUT "1\n", join(",", @groups), "\n\n";
        buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<wlan_off($id, $password, @group)>

Block groups' access to the wlan

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@groups>

The groups names to block access to the wlan

=back

=head3 Description

This wraps the command
C<wlan_on_off.sh --trigger=off --grouplist=group1,group2,...>, where
C<group1,group2,...> are the groups in C<@groups>.

=cut

sub wlan_off {
	my $id = shift;
	my $password = shift;
	my @groups = @_;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::WLANONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set groups in list to off
	print SCRIPTOUT "0\n", join(",", @groups), "\n\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<wlan_reset_at($id, $password, $group, $time)>

Will reset system configuration at a given time

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$group>

The group corresponding to the command

=item C<$time>

The time given in seconds since beginning of the epoch (1970-01-01 00:00:00)

=back

=head3 Description

Resets all configuration changes to values stored in the
Schulkonsole::LessonSession of C<$group> at time C<$time>.
This includes changes done with the functions in Schulkonsole::Radius.

=cut

sub wlan_reset_at {
	my $id = shift;
	my $password = shift;
	my $group = shift;
	my $time = shift;

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::WLANRESETATAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "$group\n$time\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}





sub read_group_file {
        my $filename = shift;

        my %groups;

        my $start = '# linuxmuster.net -- automatic entries below this line';
        my $end = '# linuxmuster.net -- automatic entries above this line';
        my $ldapgroup = 'DEFAULT\s*Ldap-Group\s*==\s*([a-z\d_]+)\s*';
        
        if (not open GROUPS, "<$filename") {
                warn "$0: Cannot open $filename";
                return {};
        }
        
        my $groups_started = 0;
        while (<GROUPS>) {
                chomp;
                if (/$start/) {
                    $groups_started = 1;
                    next;
                } elsif (/$end/) {
                    $groups_started = 0;
                    last;
                } elsif ( $groups_started ) {
                    if (/^\s*#/) {
                        next;
                    } elsif (/$ldapgroup/) {
                        $groups{$1} = 1;
                    }
                }
        }

        close GROUPS;

        return \%groups;
}




=head3 C<allowed_groups_wlan()>

Returns which groups' access to the wlan is allowed

=head4 Return value

A hash with allowed group's names as key and C<1> as value.

=cut

sub allowed_groups_wlan {
	return read_group_file($Schulkonsole::Config::_allowed_groups_wlan_file);
}




=head3 C<group_defaults()>

Returns groups default values.

=head4 Return value

A hash with group's names as key and C<1> as value indicating wlan access
with one group C<default> indicating default for new groups.

=cut

sub group_defaults {
        my $filename = $Schulkonsole::Config::_group_defaults_file;

        my %groups;

        if (not open GROUPS, "<$filename") {
                warn "$0: Cannot open $filename";
                return {};
        }
        
        while (<GROUPS>) {
                chomp;
                next if /^\s*#/;
                s/\s*#.*$//;

                my ($group, $wlan)
                        = /^\s*([a-z\d_]+)\s+(on|off|-)/;
                
                if ($group) {
                        $groups{$group} = $wlan;
                }
        }

        close GROUPS;

        # set fallback values if default is undefined
        $groups{default} = 'off' if not defined $groups{default};

        return \%groups;
}




=head3 C<wlan_reset_all($id, $password)>

Resets radius settings of all groups

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

Invokes C<linuxmuster-wlan-reset --all>

=cut

sub wlan_reset_all {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::WLANRESETAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}


=head3 C<wlan_reset($id, $password, $group)>

Resets groups settings of the selected group

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$group>

Reference to group

=back

=head3 Description

Invokes C<linuxmuster-wlan-reset --group=$group.

=cut

sub wlan_reset {
        my $id = shift;
        my $password = shift;
        my $group = shift;
        
        my $pid = start_wrapper(Schulkonsole::Config::WLANRESETAPP,
                $id, $password,
                \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

        print SCRIPTOUT "$group\n";

        buffer_input(\*SCRIPTIN);

        stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}










1;
