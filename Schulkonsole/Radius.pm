use strict;
use utf8;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::RadiusError;
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

If a wrapper command fails, it usually dies with a Schulkonsole::Error::RadiusError.
The output of the failed command is stored in the Schulkonsole::Error::RadiusError.

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
	wlan_reset
	new_wlan_defaults_lines
);

my $wrapcmd = $Schulkonsole::Config::_wrapper_radius;
my $errorclass = "Schulkonsole::Error::RadiusError";


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
C<wlan_on_off --trigger=on --grouplist=group1,group2,... --userlist=user1,user2,... , where
C<group1,group2,...> are the groups in C<@groups> and
C<user1,user2,...> are the users in C<@users>

=cut

sub wlan_on {
	my $id = $_[0];
	my $password = $_[1];
	my @groups = @{$_[2]};
	my @users = @{$_[3]};

	my $umask = umask(022);
	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::WLANONOFFAPP,
		$id, $password, "1\n"
			. "groups:\n" . (@groups ? join("\n", @groups) . "\n" : "")
			. "users:\n" . (@users ? join("\n", @users) . "\n" : "") );
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
C<wlan_on_off --trigger=off --grouplist=group1,group2,...> --userlist=user1,user2,... , where
C<group1,group2,...> are the groups in C<@groups> and
C<user1,user2,...> are the users in C<@users>.

=cut

sub wlan_off {
	my $id = $_[0];
	my $password = $_[1];
	my @groups = @{$_[2]};
	my @users = @{$_[3]};

#FIXME umask kann im Wrapper gesetzt werden.
	my $umask = umask(022);
	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::WLANONOFFAPP,
		$id, $password, "0\n"
			. "groups:\n" . (@groups ? join("\n", @groups) . "\n" : "")
			. "users:\n" . (@users ? join("\n", @users) . "\n" : "") );
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
	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::WLANRESETATAPP,
		$id, $password, join(",", @groups) . "\n" . join(",",@users) . "\n$time\n");
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

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::WLANALLOWEDAPP,
		$id, $password, "\n\n", Schulkonsole::Wrapper::MODE_FILE);

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

        return { 'groups' => \%groups, 'users' => \%users, };
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

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::WLANRESETAPP,
		$id, $password, "1\n\n\n");

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
        
        Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::WLANRESETAPP,
                $id, $password, "0\n" . join(",", @groups) . "\n" . join(",", @users) . "\n");

}



=head3 C<new_wlan_defaults_lines($defaults, $enable_groups, $disable_groups, $ignore_groups,
					$enable_users, $disable_users, $ignore_users)>

Creates new wlan_defaults lines from old lines and changes.

=head3 Parameters

=over

=item C<$defaults>

Hash reference of hashes 'users' and 'groups' with wlan entries on|off|-.

=item C<$enable_groups>

Array reference with groups names to enable wlan.

=item C<$disable_groups>

Array reference with groups to disable wlan.

=item C<$ignore_groups>

Array reference with groups to ignore wlan

=item C<$enable_users>

Array reference with users names to enble wlan.

=item C<$disable_users>

Array reference with users names to disable wlan.

=item C<$ignore_users>

Array reference with users names to ignore wlan

=back

=head3 Description

Creates new lines for wlan_defaults file from old lines and new entries.

=cut

sub new_wlan_defaults_lines {
    my $defaults = shift;
    my $enable_groups = shift;
    my $disable_groups = shift;
    my $ignore_groups = shift;
    my $enable_users = shift;
    my $disable_users = shift;
    my $ignore_users = shift;
    my %wlan_default;
    $wlan_default{'groups'} = $$defaults{'groups'}{default};
    $wlan_default{'users'} = $$defaults{'users'}{default};
    my @re;


    foreach my $group (@$enable_groups) {
		$$defaults{'groups'}{$group} = 'on';
    }
    foreach my $group (@$disable_groups) {
		$$defaults{'groups'}{$group} = 'off';
    }
    foreach my $group (@$ignore_groups) {
		$$defaults{'groups'}{$group} = '-';
    }
     foreach my $user (@$enable_users) {
	    $$defaults{'users'}{$user} = 'on';
    }
    foreach my $user (@$disable_users) {
	    $$defaults{'users'}{$user} = 'off';
    }
    foreach my $user (@$ignore_users) {
	    $$defaults{'users'}{$user} = '-';
    }
	
    if (open WLANFILE, "<$Schulkonsole::Config::_wlan_defaults_file") {
            flock WLANFILE, 1;
    
        while (my $line = <WLANFILE>) {
		    my ($spaces_0, $kind, $key, $spaces_1, $wlan, $remainder)
		    = $line =~ /^(\s*)([u|g]):([A-z\d_\.\-]+)(\s+)(on|off|-)(.*)/;
		    if ($key) {
		    	$kind = ($kind eq 'u'?'users':'groups');
				if ($key eq 'default') {
				    $line = substr($kind,0,1) .":default"
					    . "$spaces_1$wlan_default{$kind}"
					    . "$remainder\n";
				    push @re, $line;
				    delete $$defaults{$kind}{default};
				} else {
				    if ($$defaults{$kind}{$key} ne $wlan_default{$kind}) { 
						$line = substr($kind,0,1) . ":$key"
						    . "$spaces_1$$defaults{$kind}{$key}"
						    . "$remainder\n";
						push @re, $line;
				    }
				    delete $$defaults{$kind}{$key};
				}
		    } else {
				push @re, $line;
		    }
        }

        close WLANFILE;
    }


    if ($$defaults{'groups'}{default}) {
            push @re,
                    sprintf("%-20s%s\n",'g:default', $$defaults{'groups'}{default});

            delete $$defaults{'groups'}{default};
    }
    if ($$defaults{'users'}{default}) {
            push @re,
                    sprintf("%-20s%s\n",'u:default', $$defaults{'users'}{default});

            delete $$defaults{'users'}{default};
    }

    my $default_groups = $$defaults{'groups'};
    foreach my $group (sort keys %$default_groups) {
	    if ($$defaults{'groups'}{$group} ne $wlan_default{'groups'}) {
		push @re,
			sprintf("%-20s%s\n",'g:'.$group, $$defaults{'groups'}{$group});
	    }
    }
    my $default_users = $$defaults{'users'};
    foreach my $user (sort keys %$default_users) {
	    if ($$defaults{'users'}{$user} ne $wlan_default{'users'}) {
		push @re,
			sprintf("%-20s%s\n",'u:'.$user, $$defaults{'users'}{$user});
	    }
    }
    
    return \@re;
}



1;
