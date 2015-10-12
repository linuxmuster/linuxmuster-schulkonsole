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

Schulkonsole::Radius - interface to Linuxmusterloesung Radius related commands

=head1 SYNOPSIS

 use Schulkonsole::Radius;

 my $wlan = Schulkonsole::Radius::allowed_groups_users_wlan();
 if ($$wlan{'groups'}{'07a'}) {
 	print "07a is allowed\n";
 }
 if ($$lwan{'users'}{'test'}) {
 	print "test is allowed\n"
 }
 
 my @groups = ('07a', 'p_7in1');
 my @users = ('test1', 'test2');
 Schulkonsole::Radius::wlan_on($id, $password, @groups, @users);
 Schulkonsole::Radius::wlan_off($id, $password, @groups, @users);

 Schulkonsole::Radius::wlan_reset_at($id, $password, @groups, @users, $time);
 Schulkonsole::Radius::wlan_reset_all($id, $password);

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
	allowed_groups_users_wlan
	wlan_defaults
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

=head3 C<wlan_on($id, $password, @groups, @users)>

Allow groups and users access to the wlan

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@groups>

The groups to allow wlan access

=item C<@users>

The users to allow wlan access

=back

=head3 Description

This wraps the command
C<wlan_on_off.sh --trigger=on --grouplist=group1,group2,... --userlist=user1,user2,... , where
C<group1,group2,...> are the groups in C<@groups> and
C<user1,user2,...> are the users in C<@users>

=cut

sub wlan_on {
	my $id = $_[0];
	my $password = $_[1];
	my @groups = @{$_[2]};
	my @users = @{$_[3]};

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::WLANONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set groups in list to on
	print SCRIPTOUT "1\n", join(",", @groups), "\n", join("," ,@users), "\n";
        buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<wlan_off($id, $password, @groups, @users)>

Block listed groups and users access to the wlan

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@groups>

The groups names to block access to the wlan

=item C<@users>

The users names to block access to the wlan

=back

=head3 Description

This wraps the command
C<wlan_on_off.sh --trigger=off --grouplist=group1,group2,...> --userlist=user1,user2,... , where
C<group1,group2,...> are the groups in C<@groups> and
C<user1,user2,...> are the users in C<@users>.

=cut

sub wlan_off {
	my $id = $_[0];
	my $password = $_[1];
	my @groups = @{$_[2]};
	my @users = @{$_[3]};

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::WLANONOFFAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	# set groups in list to off
	print SCRIPTOUT "0\n", join(",", @groups),"\n", join(",", @users), "\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}




=head3 C<wlan_reset_at($id, $password, @groups, @users, $time)>

Will reset system configuration at a given time

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@groups>

The groups corresponding to the command

=item C<@users>

The users corresponding to the command

=item C<$time>

The time given in seconds since beginning of the epoch (1970-01-01 00:00:00)

=back

=head3 Description

Resets all configuration changes to values stored in the
Schulkonsole::LessonSession of C<@groups> and C<@users> at time C<$time>.
This includes changes done with the functions in Schulkonsole::Radius.

=cut

sub wlan_reset_at {
	my $id = $_[0];
	my $password = $_[1];
	my @groups = @{$_[2]};
	my @users = @{$_[3]};
	my $time = $_[4];

	my $umask = umask(022);
	my $pid = start_wrapper(Schulkonsole::Config::WLANRESETATAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT join(",", @groups),"\n", join(",",@users), "\n$time\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
	umask($umask);
}





=head3 C<allowed_groups_users_wlan($id, $password)>

Returns which groups/users access to the wlan is allowed

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

A hash of hashes with keys 'users' and 'groups' with allowed groups/users names as key and C<1> as value.

=cut

sub allowed_groups_users_wlan {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::WLANALLOWEDAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "\n\n";

	my $in;
	{
		local $/ = undef;
		$in = <SCRIPTIN>;
	}

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);


	my $compartment = new Safe;

	return $compartment->reval($in);
}








=head3 C<wlan_defaults()>

Returns wlan default values.

=head4 Return value

A hash of 'users' and 'groups' hashes with names as key and C<1> as value indicating wlan access
with one group C<default> indicating default for new groups and one user C<default> indicating
default for new users.

=cut

sub wlan_defaults {
        my $filename = $Schulkonsole::Config::_wlan_defaults_file;

        my %groups;
        my %users;

        if (not open WLAN, "<$filename") {
                warn "$0: Cannot open $filename";
                return {};
        }
        
        while (<WLAN>) {
                chomp;
                next if /^\s*#/;
                s/\s*#.*$//;

                my ($kind,$key, $status)
                        = /^\s*([u|g]):([a-z\d_]+)\s+(on|off|-)/;
                if ($kind eq 'u' and $key) {
                	$users{$key} = $status;
                } elsif ($kind eq 'g' and $key) {
                        $groups{$key} = $status;
                }
        }

        close WLAN;

        # set fallback values if default is undefined
        $users{default} = 'off' if not defined $users{default};
        $groups{default} = 'off' if not defined $groups{default};

        return { 'groups' => %groups, 'users' => %users, };
}




=head3 C<wlan_reset_all($id, $password)>

Resets radius settings of all groups and users

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


=head3 C<wlan_reset($id, $password, @groups, @users)>

Resets settings of the selected groups and users

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@groups>

Groups to reset wlan.

=item C<@users>

Users to reset wlan.

=back

=head3 Description

Invokes C<linuxmuster-wlan-reset --grouplist=group1,group2,group3,... --userlist=user1,user2,user3,... .

=cut

sub wlan_reset {
        my $id = $_[0];
        my $password = $_[1];
        my @groups = @{$_[2]};
        my @users = @{$_[3]};
        
        my $pid = start_wrapper(Schulkonsole::Config::WLANRESETAPP,
                $id, $password,
                \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

        print SCRIPTOUT join(",", @groups),"\n", join(",", @users),"\n";

        buffer_input(\*SCRIPTIN);

        stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}










1;
