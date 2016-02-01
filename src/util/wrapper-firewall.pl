#! /usr/bin/perl
#
# thomas@linuxmuster.net
# 22.11.2013
#

=head1 NAME

wrapper-firewall.pl - wrapper for configuration of firewall

=head1 SYNOPSIS

 my $id = $userdata{id};
 my $password = 'secret';
 my $app_id = Schulkonsole::Config::INTERNETONOFFAPP;

 open SCRIPT, "| $Schulkonsole::Config::_wrapper_firewall";
 print SCRIPT <<INPUT;
 $id
 $password
 $app_id
 1
 10.16.2.1
 10.16.2.3

 INPUT

=head1 DESCRIPTION

=cut

use strict;
use lib '/usr/share/schulkonsole';
use open ':utf8';
use open ':std';
use Sophomorix::SophomorixAPI;
use Sophomorix::SophomorixConfig;
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Encode;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::FirewallError;
use Schulkonsole::Firewall;
use Schulkonsole::RoomSession;
use Schulkonsole::Sophomorix;

my $id = <>;
$id = int($id);
my $password = <>;
chomp $password;

my $userdata = Schulkonsole::DB::verify_password_by_id($id, $password);
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHENTICATED_ID
      )
	unless $userdata;


my $app_id = <>;
($app_id) = $app_id =~ /^(\d+)$/;
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST
      )
	unless defined $app_id;

my $app_name = $Schulkonsole::Config::_id_root_app_names{$app_id};
exit (  Schulkonsole::Error::Error::WRAPPER_APP_ID_DOES_NOT_EXIST
      )
	unless defined $app_name;



my $permissions = Schulkonsole::Config::permissions_apps();
my $groups = Schulkonsole::DB::user_groups(
	$$userdata{uidnumber}, $$userdata{gidnumber}, $$userdata{gid});
# FIXME: workaround for non existing students group!
if(! (defined $$groups{teachers} or defined $$groups{domadmins})) {
	$$groups{'students'} = 1;
}

my $is_permission_found = 0;
foreach my $group (('ALL', keys %$groups)) {
	if ($$permissions{$group}{$app_name}) {
		$is_permission_found = 1;
		last;
	}
}
exit (  Schulkonsole::Error::Error::WRAPPER_UNAUTHORIZED_ID
      )
	unless $is_permission_found;


SWITCH: {
	(   $app_id == Schulkonsole::Config::INTERNETONOFFAPP
	 or $app_id == Schulkonsole::Config::INTRANETONOFFAPP) and do {
		internet_on_off_app();
		last SWITCH;
	 };
	$app_id == Schulkonsole::Config::URLFILTERONOFFAPP and do {
		urlfilter_on_off_app();
		last SWITCH;
	};
	$app_id == Schulkonsole::Config::UPDATELOGINSAPP and do {
		update_logins_app();
		last SWITCH;
	};
	$app_id == Schulkonsole::Config::URLFILTERCHECKAPP and do {
		urlfilter_check_app();
		last SWITCH;
	};
	$app_id == Schulkonsole::Config::ALLONAPP and do {
		all_on_app();
		last SWITCH;
	};
	$app_id == Schulkonsole::Config::ALLONATAPP and do {
		all_on_at_app();
		last SWITCH;
	};
	$app_id == Schulkonsole::Config::ROOMSRESETAPP and do {
		rooms_reset_app();
		last SWITCH;
	};
}


=head3 internet_on_off

numeric constant: C<Schulkonsole::Config::INTERNETONOFFAPP>

=head4 Description

invokes C<<
internet_on_off.sh --trigger=<on|off> --hostlist=<host1,host2,...,hostn>
>>


=head4 Parameters from standard input

=over

=item trigger

C<1> (on) or C<0> (off)

=item mac

IP addresses one per line, end with empty line

Format of address is x.x.x.x where x is a decimal value.

=back


=head3 intranet_on_off

numeric constant: C<Schulkonsole::Config::INTRANETONOFFAPP>

=head4 Description

invokes C<<
intranet_on_off.sh --trigger=<on|off> --hostlist=<host1,host2,...,hostn>
>>


=head4 Parameters from standard input

=over

=item trigger

C<1> (on) or C<0> (off)

=item mac

IP addresses one per line, end with empty line

Format of address is x.x.x.x where x is a decimal value.

=back

=cut

sub internet_on_off_app() {
	my $trigger = <>;
	$trigger = int($trigger) ? 'on' : 'off';

	my @hosts;
	while (my $host = <>) {
		last if $host =~ /^$/;

		($host) = $host =~ /^([\w.-]+)$/i;
		exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_HOST
		      )
			unless $host;

		push @hosts, $host;
	}
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_NO_HOSTS
	      )
		unless @hosts;

	my $cmd = ($app_id == Schulkonsole::Config::INTERNETONOFFAPP ?
	             $Schulkonsole::Config::_cmd_internet_on_off
	           : $Schulkonsole::Config::_cmd_intranet_on_off);

	my $opts;
	$opts = "--trigger=$trigger --hostlist=" . join(',', @hosts);

	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	local $) = 0;
	local $( = $);
	umask(022);
	exec Schulkonsole::Encode::to_cli("$cmd $opts") or return;
}

=head3 urlfilter_on_off

numeric constant: C<Schulkonsole::Config::URLFILTERONOFFAPP>

=head4 Description

invokes C<<
urlfilter_on_off.sh --trigger=<on|off> --hostlist=<host1,host2,...,hostn>
>>


=head4 Parameters from standard input

=over

=item trigger

C<1> (on) or C<0> (off)

=item host

hostnames one per line, end with empty line

=back

=cut

sub urlfilter_on_off_app() {
	my $trigger = <>;
	$trigger = int($trigger) ? 'on' : 'off';

	my @hosts;
	while (my $host = <>) {
		last if $host =~ /^$/;

		($host) = $host =~ /^([\w.-]+)$/i;
		exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_HOST
		      )
			unless $host;

		push @hosts, $host;
	}
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_NO_HOSTS
	      )
		unless @hosts;

	my $opts = "--trigger=$trigger --hostlist=" . join(',', @hosts);

	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	local $) = 0;
	local $( = $);
	umask(022);
	exec Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_urlfilter_on_off $opts");
}

=head3 update_logins

numeric constant: C<Schulkonsole::Config::UPDATELOGINSAPP>

=head4 Description

invokes C<update-logins.sh>

=cut

sub update_logins_app() {
	my $room = <>;
	($room) = $room =~ /^([\w -]+)$/;
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_ROOM
	      )
		unless $room;
	# set ruid
	local $< = $>;
	exec Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_update_logins $room");
}

=head3 urlfilter_check

numeric constant: C<Schulkonsole::Config::URLFILTERCHECKAPP>

=head4 Description

invokes C<check_urlfilter.sh>

=cut

sub urlfilter_check_app() {
	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	my $ret = system(Schulkonsole::Encode::to_cli(
	     	"$Schulkonsole::Config::_cmd_urlfilter_check >/dev/null 2>/dev/null"));
	if($ret){
		print "0\n";
	} 
	else {
		print "1\n";
	}
	exit 0;
}

=head3 all_on

numeric constant: C<Schulkonsole::Config::ALLONAPP>

=head4 Description

Resets the workstation settings in a room

=head4 Parameters from standard input

=over

=item C<room>

The name of the room

=back

=cut

sub all_on_app() {
	my $room = <>;
	($room) = $room =~ /^([\w -]+)$/;
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_ROOM
	      )
		unless $room;

	my $room_session = room_session($room);

	all_on($room_session);

	$room_session->delete();

	exit 0;
}

=head3 all_on_at

numeric constant: C<Schulkonsole::Config::ALLONATAPP>

=head4 Description

Resets the workstation settings in a room at a given time

=head4 Parameters from standard input

=over

=item C<room>

The name of the room

=item C<time>

Absolute time in seconds since the Epoch

=back

=cut

sub all_on_at_app(){
	my $room = <>;
	($room) = $room =~ /^([\w -]+)$/;
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_ROOM
	      )
		unless $room;

	my $time = <>;
	($time) = $time =~ /^(\d+)$/;
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_LESSONTIME
	      )
		unless $time;

	{ # write values and close session
	my $room_session = room_session($room);
	$room_session->param('end_time', $time);
	}

	my $pid = fork;
	exit (  Schulkonsole::Error::Error::WRAPPER_CANNOT_FORK
	      )
		unless defined $pid;

	if (not $pid) {
		close STDIN;
		close STDOUT;
		close STDERR;
		open STDOUT, '>>', '/dev/null' or die;
		open STDERR, '>>&', *STDOUT or die;

		sleep $time - $^T;

		my $room_session = room_session($room);

		my $stored_room = $room_session->param('name');
		exit (  Schulkonsole::Error::FirewallError::WRAPPER_CANNOT_READ_ROOMFILE
		      )
			unless $stored_room;
		my $stored_id = $room_session->param('user_id');
		exit (  Schulkonsole::Error::FirewallError::WRAPPER_CANNOT_READ_ROOMFILE
		      )
			unless $stored_id;
		my $stored_time = $room_session->param('end_time');
		exit (  Schulkonsole::Error::FirewallError::WRAPPER_CANNOT_READ_ROOMFILE
		      )
			unless $stored_time;
		my $is_exam_mode = $room_session->param('test_step');

		if (    $stored_time == $time
		    and $stored_id == $id
		    and $stored_room eq $room
			and not $is_exam_mode) {

			Schulkonsole::DB::reconnect();
			all_on($room_session);

			$room_session->delete();
		}
	}

	exit 0;
}

=head3 rooms_reset

numeric constant: C<Schulkonsole::Config::ROOMSRESETAPP>

=head4 Description

Resets the workstation settings in a room

=head4 Parameters from standard input

=over

=item C<scope>

0 (= all)

=back

=cut

sub rooms_reset_app(){
	my $scope = <>;
	($scope) = $scope =~ /^([01])$/;
	exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_ROOM_SCOPE
	      )
		unless defined $scope;

	if ($scope == 0) {
		my $opts = '--all';
		$< = $>;
		exec Schulkonsole::Encode::to_cli(
		     	"$Schulkonsole::Config::_cmd_linuxmuster_reset $opts")
			or return;
	} else {
		my @rooms_reset;
		while (<>) {
			last if /^$/;
			my ($room) = /^([\w -]+)$/;
			exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_ROOM
			      )
				unless $room;
			push @rooms_reset, $room;
		}
		my @hosts_reset;
		while (<>) {
			last if /^$/;
			my ($host) = /^([\w.-]+)$/i;
			exit (  Schulkonsole::Error::FirewallError::WRAPPER_INVALID_HOST
			      )
				unless $host;
			push @hosts_reset, $host;
		}

		my $is_error = 0;
		local $< = $>;
		local $) = 0;
		local $( = $);
		umask(022);	# otherwise linuxmuster-reset will create files without
		            # read permissions for us

		my $cmd_encoded
			= Schulkonsole::Encode::to_cli(
		      	"$Schulkonsole::Config::_cmd_linuxmuster_reset --room=");
		foreach my $room (@rooms_reset) {
			system(  $cmd_encoded
			       . Schulkonsole::Encode::to_cli("\Q$room\E")) == 0
				or $is_error++;
		}

		$cmd_encoded
			= Schulkonsole::Encode::to_cli(
		      	"$Schulkonsole::Config::_cmd_linuxmuster_reset --host=");
		foreach my $host (@hosts_reset) {
			system(  $cmd_encoded
			       . Schulkonsole::Encode::to_cli("\Q$host\E")) == 0
				or $is_error++;
		}

		exit 0 unless $is_error;
	}
}



exit -2;	# program error



sub room_session {
	my $room = shift;

	my $session = new Schulkonsole::RoomSession($room);

	exit (  Schulkonsole::Error::FirewallError::INVALID_SESSION  )
		unless $session;

	# 'unprivileged' is set in the main CGI-script
	# do not keep a session, that we created as root
	if (not $session->param('unprivileged')) {
		$session->delete();
		exit 0;
	}

	return $session;
}




sub all_on {
	my $room_session = shift;

	my $workstations
		= Schulkonsole::Config::workstations_room($room_session->param('name'));

	my $room = $room_session->param('name');

	if ($room_session->param('test_step')) {
		my $editing_userdata = Schulkonsole::DB::get_userdata_by_id(
				$room_session->param('user_id'));
		my $opts = "--teacher \Q$$editing_userdata{uid}"
			. ' --collect --exam'
			. " --room \Q$room";


		local $< = $>;
		local $) = 0;
		local $( = $);
		umask(022);
		system Schulkonsole::Encode::to_cli(
		       	"$Schulkonsole::Config::_cmd_sophomorix_teacher $opts");

		$opts = " --reset-room \Q$room";
		system Schulkonsole::Encode::to_cli(
		       	"$Schulkonsole::Config::_cmd_sophomorix_room $opts");


		$opts = " --hide --random --rooms \Q$room";
		system Schulkonsole::Encode::to_cli(
		       	"$Schulkonsole::Config::_cmd_sophomorix_class $opts");
	}

	my $oldsettings = $room_session->param('oldsettings');

	# reset internet, intranet, webfilter settings to old stat from session file
	my $blocked_hosts_internet
		= Schulkonsole::Firewall::blocked_hosts_internet();
	my $blocked_hosts_intranet
		= Schulkonsole::Firewall::blocked_hosts_intranet();
	my $unfiltered_hosts = Schulkonsole::Firewall::unfiltered_hosts();
	my @internet_ons;
	my @internet_offs;
	my @intranet_ons;
	my @intranet_offs;
	my @webfilter_ons;
	my @webfilter_offs;
	foreach my $workstation (keys %$workstations) {
		my ($host) = $$workstations{$workstation}{ip} =~ /^([\w.-]+)$/i;
		if ($$oldsettings{blocked_hosts_internet} 
		    and $$oldsettings{blocked_hosts_internet}{$host}
		    and ! $$blocked_hosts_internet{$host}) {
			push @internet_offs, $host;
		} elsif ($$oldsettings{blocked_hosts_internet}
                    and ! $$oldsettings{blocked_hosts_internet}{$host}
		    and $$blocked_hosts_internet{$host}) {
                        push @internet_ons, $host;
		}
		if ($$oldsettings{blocked_hosts_intranet}
		    and $$oldsettings{blocked_hosts_intranet}{$host}
                    and ! $$blocked_hosts_intranet{$host}) {
			push @intranet_offs, $host;
		} elsif ($$oldsettings{blocked_hosts_intranet}
		    and ! $$oldsettings{blocked_hosts_intranet}{$host}
		    and $$blocked_hosts_intranet{$host}) {
			push @intranet_ons, $host;
		}
		if ($$oldsettings{unfiltered_hosts}
		    and $$oldsettings{unfiltered_hosts}{$host}
                    and ! $$unfiltered_hosts{$host}) {
			push @webfilter_offs, $host;
        } elsif ($$oldsettings{unfiltered_hosts}
                    and ! $$oldsettings{unfiltered_hosts}{$host}
                    and $$unfiltered_hosts{$host}) {
			push @webfilter_ons, $host;
		}
	}

	# set ruid, so that ssh searches for .ssh/ in /root
	local $< = $>;
	local $) = 0;
	local $( = $);
	umask(022);

	if (@webfilter_offs) {
		my $opts = "--trigger=off --hostlist=" . join(',', @webfilter_offs);

		system $Schulkonsole::Config::_cmd_urlfilter_on_off
				. ' ' . $opts;
	}
	if (@webfilter_ons) {
		my $opts = "--trigger=on --hostlist=" . join(',', @webfilter_ons);

		system $Schulkonsole::Config::_cmd_urlfilter_on_off
				. ' ' . $opts;
	}

	if (@internet_ons) {
		my $opts = "--trigger=on --hostlist=" . join(',', @internet_ons);

		system $Schulkonsole::Config::_cmd_internet_on_off
			. ' ' . $opts;
	}
	if (@internet_offs) {
		my $opts = "--trigger=off --hostlist=" . join(',', @internet_offs);

		system $Schulkonsole::Config::_cmd_internet_on_off
			. ' ' . $opts;
	}

	if (@intranet_ons) {
		my $opts = "--trigger=on --hostlist=" . join(',', @intranet_ons);
		
		system $Schulkonsole::Config::_cmd_intranet_on_off
			. ' ' . $opts;
	}
	if (@intranet_offs) {
		my $opts = "--trigger=off --hostlist=" . join(',', @intranet_offs);

		system $Schulkonsole::Config::_cmd_intranet_on_off
			. ' ' . $opts;
	}

	# reset printer settings to old state from session file
	if ($$oldsettings{printers_accept}) {
		my %value_type = (
			DenyUser => 2,
			Accepting => 1,
		);
	
		open PRINTERSCONF, '<', Schulkonsole::Encode::to_fs(
		     	$Schulkonsole::Config::_cups_printers_conf_file)
			or exit (  Schulkonsole::Error::FirewallError::WRAPPER_CANNOT_OPEN_PRINTERSCONF
			         );

		my $printer;
		my %printer_info;
		while (<PRINTERSCONF>) {
			if (/^<.*Printer\s+(.+)>/) {
				$printer = $1;
			} elsif (m:^</:) {
				$printer = undef;
			} elsif (    my ($name, $value) = /^([DA]\S+)\s+(.*)$/
			         and $printer) {
				if ($value_type{$name}) {
					if ($value_type{$name} == 2) {
						$printer_info{$printer}{$name}{$value} = 1;
					} else {
						$printer_info{$printer}{$name} = $value;
					}
				}
			}
		}
	
		close PRINTERSCONF;


		foreach my $printer (keys %{ $$oldsettings{printers_accept} }) {
			if (    $printer_info{$printer}
			    and $$oldsettings{printers}{$printer}) {
				if ($$oldsettings{printers_accept}{$printer}) {
					if ($printer_info{$printer}{Accepting} ne 'Yes') {
						system Schulkonsole::Encode::to_cli(
							"$Schulkonsole::Config::_cmd_printer_accept \Q$printer\E");
					}
				} else {
					if ($printer_info{$printer}{Accepting} eq 'Yes') {
						system Schulkonsole::Encode::to_cli(
							"$Schulkonsole::Config::_cmd_printer_reject \Q$printer\E");
					}
				}
	
				my $old_deny_users
					= $$oldsettings{printers}{$printer}{DenyUser};
				my %deny_users;
				if ($printer_info{$printer}{DenyUser}) {
					%deny_users = %{ $printer_info{$printer}{DenyUser} };
				}

				if ($old_deny_users) {
					foreach my $user (keys %$old_deny_users) {
						if ($$old_deny_users{$user}) {
							$deny_users{$user} = 1 unless $deny_users{$user};
						} else {
							delete $deny_users{$user}
								if exists $deny_users{$user};
						}
					}
				}
				my @deny_users = map { quotemeta } keys %deny_users;
	
				if ( @deny_users ) {
					system Schulkonsole::Encode::to_cli(
					       	$Schulkonsole::Config::_cmd_printer_lpadmin
					       	. " -p\Q$printer\E -u deny:"
					       	. join(',', @deny_users));
				} else {
					system Schulkonsole::Encode::to_cli(
					       	$Schulkonsole::Config::_cmd_printer_lpadmin
					       	. " -p\Q$printer\E -u deny:none");
				}
			}
		}
	}

	# reset share states to old settings from session file
	if ($$oldsettings{share_states}) {
		my $old_share_states = $$oldsettings{share_states};
		my @shares_on;
		my @shares_off;
		my $shareuserdata;
		foreach my $login_id (keys %$old_share_states) {
			$shareuserdata = Schulkonsole::DB::get_userdata_by_id($login_id);
			if( $$old_share_states{$login_id}) {
				push @shares_on, $$shareuserdata{uid};
			} elsif( not $$old_share_states{$login_id}) {
				push @shares_off, $$shareuserdata{uid};
			}
		}

		system Schulkonsole::Encode::to_cli(
		       	$Schulkonsole::Config::_cmd_sophomorix_teacher
		       	. " --teacher \Q$$userdata{uid}\E --share --users "
		       	. join(',', @shares_on))
			if @shares_on;
		system Schulkonsole::Encode::to_cli(
		       	$Schulkonsole::Config::_cmd_sophomorix_teacher
		       	. " --teacher \Q$$userdata{uid}\E --noshare --users "
		       	. join(',', @shares_off))
			if @shares_off;
	}


	return 1;
}

