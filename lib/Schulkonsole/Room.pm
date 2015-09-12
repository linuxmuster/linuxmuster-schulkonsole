use strict;
use POSIX qw(strftime);
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::Firewall;
use Schulkonsole::RoomSession;
use Schulkonsole::Sophomorix;
use Sophomorix::SophomorixBase;

=head1 NAME

Schulkonsole::Room - Store information about room

=cut

package Schulkonsole::Room;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter Schulkonsole::RoomSession);
@EXPORT_OK = qw(
);

my @passwort_zeichen = Sophomorix::SophomorixBase::get_passwd_charlist();




=head1 DESCRIPTION

=head2 Public Methods

=head3 C<new Room($session)>

=cut

sub new {
	my $class = shift;
	my $session = shift;

	my $room;
	my $id;

	my $q = $session->query();
	my $remote_room = $session->{template_vars}{remote_room};


	my $classrooms = Schulkonsole::Config::classrooms();
	$room = $q->param('rooms');
	if ($room) {
		foreach my $classroom (@$classrooms) {
			if ($classroom eq $room) {
				$session->param('room', $room);
				last;
			}
		}
	}

	$room = $session->param('room');
	if (not $room) {
		foreach my $classroom (@$classrooms) {
			if ($classroom eq $remote_room) {
				$session->param('room', $remote_room);
				$room = $remote_room;
				last;
			}
		}
	}


	return undef unless $room;



	$id = $session->userdata('id');

	my $this = new Schulkonsole::RoomSession($room);

	$this->param('unprivileged', 1);


	my $editing_userdata = {};
	my $is_editing = 0;
	my $is_allowed_stopedit = 0;
	if ($this->param('edit')) {
		$editing_userdata
			= Schulkonsole::DB::get_userdata_by_id(
				$this->param('user_id'));
		if ($$editing_userdata{id} == $id) {
			$is_editing = 1;
			$is_allowed_stopedit = 1;
		} elsif ($this->param('name') eq $remote_room) {
			# FIXME - Können hier Schüler den Unterricht beenden?
			$is_allowed_stopedit = 2;
		}
	}

	$this->{_ROOMDATA} = {
		name => $room,
		id => $id,
		editing_userdata => $editing_userdata,
		is_editing => $is_editing,
		is_allowed_stopedit => $is_allowed_stopedit,
	};



	bless $this, $class;
}




=head3 C<info()>

=cut

sub info {
	my $this = shift;
	my $key = shift;

	return $this->{_ROOMDATA}{$key};
}




=head3 C<start_lesson()>

=cut

sub start_lesson {
	my $this = shift;
	my $id = shift;
	my $password = shift;

	if (not $this->{_ROOMDATA}{name}) {
		die new Schulkonsole::Error(Schulkonsole::Error::UNKNOWN_ROOM);
	}


	$this->{_ROOMDATA}{editing_userdata}
		= Schulkonsole::DB::get_userdata_by_id($this->{_ROOMDATA}{id});

	$this->{_ROOMDATA}{is_editing} = 1;
	$this->{_ROOMDATA}{is_allowed_stopedit} = 1;

	$this->param('name', $this->{_ROOMDATA}{name});
	$this->param('user_id', $this->{_ROOMDATA}{id});
	$this->param('edit', 1);

	$this->param('start_time',$^T);


	my $blocked_hosts_internet_all
		= Schulkonsole::Firewall::blocked_hosts_internet();
	my $blocked_hosts_intranet_all
		= Schulkonsole::Firewall::blocked_hosts_intranet();
	my $unfiltered_hosts_all = Schulkonsole::Firewall::unfiltered_hosts();

	my $lml_majorversion = "$Schulkonsole::Config::_lml_majorversion";
	my %blocked_hosts_internet;
	my %blocked_hosts_intranet;
	my %unfiltered_hosts;

	my $workstations =
		Schulkonsole::Config::workstations_room($this->{_ROOMDATA}{name});
	foreach my $workstation (keys %$workstations) {
		my ($mac) = $$workstations{$workstation}{mac} =~ /^(\w{2}(?::\w{2}){5})$/;
		my ($host) = $$workstations{$workstation}{ip} =~ /^([\w.-]+)$/i;

		if ($lml_majorversion >= 6.1) {
			$blocked_hosts_internet{$mac} = 1
				if ($$blocked_hosts_internet_all{$host});
			$blocked_hosts_intranet{$mac} = 1
				if ($$blocked_hosts_intranet_all{$host});
			$unfiltered_hosts{$mac} = 1
				if ($$unfiltered_hosts_all{$host});
		} else {
			$blocked_hosts_internet{$mac} = 1
				if ($$blocked_hosts_internet_all{$mac});
			$blocked_hosts_intranet{$mac} = 1
				if ($$blocked_hosts_intranet_all{$mac});
			$unfiltered_hosts{$mac} = 1
				if ($$unfiltered_hosts_all{$mac});
		}
	}


	my $printers
		= Schulkonsole::Config::printers_room($this->{_ROOMDATA}{name});
	my $printer_info = Schulkonsole::Printer::printer_info($id, $password);
	my %printers_accept;
	foreach my $printer (@$printers) {
		$printers_accept{$printer} =
			$$printer_info{$printer}{Accepting} eq 'Yes';
	}


	my $workstation_users = workstation_users();
	my @login_ids;
	foreach my $host (keys %$workstation_users) {
		foreach my $userdata (@{ $$workstation_users{$host} }) {
			push @login_ids, $$userdata{id};
		}
	}
	my $share_states
		= Schulkonsole::Sophomorix::share_states($id, $password, @login_ids);
	$this->param('oldsettings', {
		blocked_hosts_internet => \%blocked_hosts_internet,
		blocked_hosts_intranet => \%blocked_hosts_intranet,
		unfiltered_hosts => \%unfiltered_hosts,
		printers_accept => \%printers_accept,
		share_states => $share_states,
	});
	$this->end_lesson_at($id, $password, int($^T / 300) * 300 + 2700);
}




=head3 C<end_lesson_now($id, $password)>

=cut

sub end_lesson_now {
	my $this = shift;
	my $id = shift;
	my $password = shift;

	$this->unlock();
	Schulkonsole::Firewall::all_on($id, $password, $this->{_ROOMDATA}{name});
	$this->lock();

	$this->delete();
}




=head3 C<end_lesson_at($id, $password, $end_time)>

=cut

sub end_lesson_at {
	my $this = shift;
	my $id = shift;
	my $password = shift;
	my $end_time = shift;

	$this->unlock();
	Schulkonsole::Firewall::all_on_at($id, $password,
		$this->{_ROOMDATA}{name},
		$end_time);
	$this->lock();
}




=head3 C<change_workstation_passwords($password)>

=cut

sub change_workstation_passwords {
	my $this = shift;
	my $id = shift;
	my $password = shift;
	my $newpassword = shift;

	return Schulkonsole::Sophomorix::change_room_password(
		$id, $password,
		$newpassword,
		$this->{_ROOMDATA}{name});
}




=head3 C<workstation_users()>

=cut

my %workstation_users;
sub workstation_users {
	my $this = shift;

	return \%workstation_users if %workstation_users;


	my $workstations = Schulkonsole::Config::workstations_room(
		$this->{_ROOMDATA}{name});

	foreach my $workstation (keys %$workstations) {
		my $filename = Schulkonsole::Config::workstation_file($workstation);
		if (-e $filename) {
			open WORKSTATION, "<$filename"
				or die "$0: Cannot open $filename: $!\n";

			my @users;
			while (<WORKSTATION>) {
				chomp;
				push @users, $_;
			};
			close WORKSTATION;

			$workstation_users{$workstation} = [];
			foreach my $uid (@users) {
				my $userdata = Schulkonsole::DB::get_userdata($uid);
				if ($userdata) {
					push @{ $workstation_users{$workstation} }, $userdata;
				}
			}
		}
	}


	return \%workstation_users;
}



=head3 C<set_vars($session)>

Set template variables

=head4 Parameters

=over

=item C<$session>

The session to set the template variables

=back

=head4 Description

Sets template variables for this room:

=over

=item C<room>

Name of the room

=item C<editinguser>

Name of user holding a lesson

=item C<edit>

True if someone is holding a lesson

=item C<stopedit>

True if the current user is allowed to stop the lesson

=item C<endedittime>

Time of lesson to end

=item C<privilegeduser>

Comma separated list of all user's that can start a lesson and are logged
in in the room

=item C<exammode>

True if someone holds an exam

=item C<done_test_start>

True if an exam is started

=item C<done_test_handout>

True if files in the exam have been handed out

=item C<done_test_password>

True if the passwords of the workstations have been changed for the exam

=item C<todo_test_handout>

True if the next step is to hand out files

=item C<todo_test_password>

True if the next step is to change the passwords of the workstations
for the exam

=item C<todo_test_collect>

True if the next step is to collect files

=back

=cut

sub set_vars {
	my $this = shift;
	my $session = shift;

	$session->set_var('room', $this->info('name'));
	if ($this->param('edit')) {
		my $editing_userdata = $this->info('editing_userdata');
		$session->set_var('editinguser',
			"$$editing_userdata{firstname} $$editing_userdata{surname}");

		$session->set_var('edit', $this->info('is_editing'));
		$session->set_var('stopedit', $this->info('is_allowed_stopedit'));

		my $end_time = $this->param('end_time');
		$session->set_var('endedittime',
			POSIX::strftime('%H:%M', localtime($end_time))) if $end_time > 0;
	} else {
		my $permissions = Schulkonsole::Config::permissions_pages();
		my $users = $this->workstation_users();

		my @privileged_users;
		foreach my $workstation (keys %$users) {
			foreach my $userdata (@{ $$users{$workstation} }) {
				my $groups = Schulkonsole::DB::user_groups(
					$$userdata{uidnumber},
					$$userdata{gidnumber},
					$$userdata{gid});
				my @groupnames = keys %$groups;
				foreach my $group (('ALL', @groupnames)) {
					if ($$permissions{$group}{room}) {
						push @privileged_users,
						     "$$userdata{firstname} $$userdata{surname}";
						last;
					}
				}
			}
		}
		$session->set_var('privilegeduser', join(', ', @privileged_users));
	}

	my $test_step = $this->param('test_step');
	$session->set_var('exammode', $test_step);

	    $test_step > 0
	and $session->set_var('done_test_start', 1)
	and $test_step > 1
	and $session->set_var('done_test_handout', 1)
	and $test_step > 2
	and $session->set_var('done_test_password', 1);


	if ($test_step == 1) {
		$session->set_var('todo_test_handout', 1)
	} elsif ($test_step == 2) {
		$session->set_var('todo_test_password', 1)
	} elsif ($test_step == 3) {
		$session->set_var('todo_test_collect', 1)
	}

}




sub random_password {
	my $len = shift;
	my $re = Sophomorix::SophomorixBase::get_random_password(10,undef,@passwort_zeichen);
	return $re;
}






1;
