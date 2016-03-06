#! /usr/bin/perl
#
# fschuett@gymnasium-himmelsthuer.de
# 06.08.2014
#

=head1 NAME

wrapper-radius.pl - wrapper for configuration of radius

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::WLANONOFFAPP;

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_radius";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 1
 teachers
 extra

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Schulkonsole::Wrapper;
use Sophomorix::SophomorixAPI;
use Sophomorix::SophomorixConfig;
use Sophomorix::SophomorixPgLdap;
use DBI;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::RadiusError;
use Schulkonsole::Radius;
use Schulkonsole::LessonSession;
use Data::Dumper;

my $userdata=Schulkonsole::Wrapper::wrapper_authenticate();
my $id = $$userdata{id};

my $app_id = Schulkonsole::Wrapper::wrapper_authorize($userdata);

SWITCH: {
	$app_id == Schulkonsole::Config::WLANALLOWEDAPP and do {
		allowed_groups_users_wlan();
		last SWITCH;
	};
	
	$app_id == Schulkonsole::Config::WLANONOFFAPP and do {
		wlan_on_off();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::WLANRESETAPP and do {
		wlan_reset();
		last SWITCH;
	};

	$app_id == Schulkonsole::Config::WLANRESETATAPP and do {
		wlan_reset_at();
		last SWITCH;
	};

};

exit -2;	# program error
		
=head3 allowed_groups_users_wlan

numeric constant: C<Schulkonsole::Config::WLANALLOWEDAPP>

=head4 Description

Uses Sophomorix commands to read groups users from wlan unix group.

=head4 Parameters from standard input

=over

=head4 Return parameters

The function returns a hash of hashes with keys users and group
and the currently allowed users and groups as keys with value C<1>.

=back

=cut

sub allowed_groups_users_wlan {
	
	my @members_by_option=Sophomorix::SophomorixPgLdap::fetchmembers_by_option_from_project($Schulkonsole::Config::_wlan_ldap_group);
	my @pgroups=Sophomorix::SophomorixPgLdap::fetchgroups_from_project($Schulkonsole::Config::_wlan_ldap_group);
	my @projects=Sophomorix::SophomorixPgLdap::fetchprojects_from_project($Schulkonsole::Config::_wlan_ldap_group);
	my @groups = (@pgroups, @projects);
	my %groups_hash = map { $_ => 1 } @groups;
	my %users_hash = map { $_ => 1 } @members_by_option;
	
	my %wlan;
	$wlan{'groups'} = \%groups_hash;
	$wlan{'users'} = \%users_hash;
	my $data = Data::Dumper->new([ \%wlan ]);
	$data->Terse(1);
	$data->Indent(0);
	print $data->Dump;

	exit 0;
}


=head3 wlan_on_off

numeric constant: C<Schulkonsole::Config::WLANONOFFAPP>

=head4 Description

invokes C<<
wlan_on_off.sh --trigger=<on|off> --grouplist=<group1,group2,...,groupn> 
               --userlist=<user1,user2,...,usern>
>>


=head4 Parameters from standard input

=over

=item trigger

C<1> (on) or C<0> (off)

=item grouplist

comma separated list of group names

=item userlist

comma separated list of user names

=back

=cut

sub wlan_on_off {
	my $trigger = <>;
	$trigger = int($trigger) ? 'on' : 'off';
	
	my $grouplist = <>;
	($grouplist) = $grouplist =~ /^([a-z0-9\_,]+)$/;
	my @lessongroups = split(",",$grouplist);
	@lessongroups = grep { $_ =~ /^[a-z0-9\_]+$/ } @lessongroups;
	$grouplist = join(",", @lessongroups);
	
	my $userlist = <>;
	($userlist) = $userlist =~ /^([a-z0-9,]+)$/;
	my @lessonusers = split(",",$userlist);
	@lessonusers = grep { $_ =~ /^[a-z0-9]+$/ } @lessonusers;
	$userlist = join(",", @lessonusers);
	
	exit (  Schulkonsole::Error::RadiusError::WRAPPER_NO_GROUPS )
		unless $userlist or $grouplist;


	my $cmd =  $Schulkonsole::Config::_cmd_wlan_on_off;

	my $opts;
	$opts = "--trigger=$trigger";
	$opts .= " --grouplist=$grouplist" if $grouplist;
	$opts .= " --userlist=$userlist" if $userlist;
	$opts .= " --caller administrator";

	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	local $) = 0;
	local $( = $);
	umask(022);

	system(Schulkonsole::Encode::to_cli("$cmd $opts"));
	
	exit 0;
}


=head3 wlan_reset

numeric constant: C<Schulkonsole::Config::WLANRESETAPP>

=head4 Description

Resets the groups settings in a group

=head4 Parameters from standard input

=over

=item C<all>

Reset all users,groups to default C<1> or only specified C<0>

=item C<grouplist>

The names of the groups C<group1,group2,...,groupn>

=item C<userlist>

The names of the users C<user1,user2,...,usern>

=back

=cut

sub wlan_reset {
	my $all = <>;
	($all) = $all =~ /^[0|1]$/;
	exit (  Schulkonsole::Error::RadiusError::WRAPPER_INVALID_GROUP )
		unless $all;
	my $grouplist = <>;
	($grouplist) = $grouplist =~ /^([a-z0-9\_,]+)$/;
	my @lessongroups = split(",",$grouplist);
	@lessongroups = grep { $_ =~ /^[a-z0-9\_]+$/ } @lessongroups;
	$grouplist = join(",", @lessongroups);
	
	my $userlist = <>;
	($userlist) = $userlist =~ /^([a-z0-9,]+)$/;
	my @lessonusers = split(",",$userlist);
	@lessonusers = grep { $_ =~ /^[a-z0-9]+$/ } @lessonusers;
	$userlist = join(",", @lessonusers);
	
	exit (  Schulkonsole::Error::RadiusError::WRAPPER_NO_GROUPS )
		unless $userlist or $grouplist;

    _wlan_reset($all,$grouplist,$userlist);

    exit 0;
}


=head3 wlan_reset_at

numeric constant: C<Schulkonsole::Config::WLANRESETATAPP>

=head4 Description

Resets the wlan settings for a group at a given time

=head4 Parameters from standard input

=over

=item C<grouplist>

The names of the groups C<group1,group2,...,groupn>

=item C<userlist>

The names of the users <user1,user2,...,usern>

=item C<time>

Absolute time in seconds since the Epoch

=back

=cut

sub wlan_reset_at {
	my $grouplist = <>;
	($grouplist) = $grouplist =~ /^([a-z0-9\_,]+)$/;
	my @lessongroups = split(",",$grouplist);
	@lessongroups = grep { $_ =~ /^[a-z0-9\_]+$/ } @lessongroups;
	$grouplist = join(",", @lessongroups);
	
	my $userlist = <>;
	($userlist) = $userlist =~ /^([a-z0-9,]+)$/;
	my @lessonusers = split(",",$userlist);
	@lessonusers = grep { $_ =~ /^[a-z0-9]+$/ } @lessonusers;
	$userlist = join(",", @lessonusers);
	
	exit (  Schulkonsole::Error::RadiusError::WRAPPER_NO_GROUPS )
		unless $userlist or $grouplist;

	my $time = <>;
	($time) = $time =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::RadiusError::WRAPPER_INVALID_LESSONTIME )
		unless $time;

	my $lessongroup;
	$lessongroup = $lessongroups[0] if $#lessongroups >= 0;
	exit (  Schulkonsole::Error::RadiusError::WRAPPER_NO_GROUPS )
		unless $lessongroup;
	
	{ # write values and close session
	my $group_session = group_session($lessongroup);
	$group_session->param('end_time', $time);
	}

	my $pid = fork;
	exit (  Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK )
		unless defined $pid;

	if (not $pid) {
		close STDIN;
		close STDOUT;
		close STDERR;
		open STDOUT, '>>', '/dev/null' or die;
		open STDERR, '>>&', *STDOUT or die;

		sleep $time - $^T;

		my $group_session = group_session($lessongroup);

		my $stored_group = $group_session->param('name');
		exit (  Schulkonsole::Error::RadiusError::WRAPPER_CANNOT_READ_GROUPFILE  )
			unless $stored_group;
		my $stored_id = $group_session->param('user_id');
		exit (  Schulkonsole::Error::RadiusError::WRAPPER_CANNOT_READ_GROUPFILE  )
			unless $stored_id;
		my $stored_time = $group_session->param('end_time');
		exit (  Schulkonsole::Error::RadiusError::WRAPPER_CANNOT_READ_GROUPFILE  )
			unless $stored_time;

		if (    $stored_time == $time
		    and $stored_id == $id
		    and $stored_group eq $lessongroup) {

			Schulkonsole::DB::reconnect();
			_wlan_reset(0,$grouplist,$userlist);

			$group_session->delete();
		}
	}

	exit 0;
}

sub group_session {
	my $lessongroup = shift;

	my $session = new Schulkonsole::LessonSession($lessongroup);

	exit (  Schulkonsole::Error::Error::WRAPPER_INVALID_SESSION_ID  )
		unless $session;

	# 'unprivileged' is set in the main CGI-script
	# do not keep a session, that we created as root
	if (not $session->param('unprivileged')) {
		$session->delete();
		exit 0;
	}

	return $session;
}




sub _wlan_reset {
	my $all = shift;
	my $grouplist = shift;
	my $userlist = shift;

	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	local $) = 0;
	local $( = $);
	umask(022);

	# reset the settings according to wlan_default instead of restoring 
	# the old state from session file
	my $opts = "";
	$opts .= " --all" if $all;
	$opts .= " --grouplist=\Q$grouplist\E" if $grouplist;
	$opts .= " --userlist=\Q$userlist\E" if $userlist;
	
	system Schulkonsole::Encode::to_cli(
	       	"$Schulkonsole::Config::_cmd_linuxmuster_wlan_reset $opts");

	return 1;
}

