use strict;
use POSIX qw(strftime);
use Schulkonsole::Config;
use Schulkonsole::DB;
use Schulkonsole::LessonSession;
use Schulkonsole::Sophomorix;
use Schulkonsole::Info;
use Schulkonsole::Error;

=head1 NAME

Schulkonsole::Lesson - Store information about lesson group

=cut

package Schulkonsole::Lesson;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter Schulkonsole::LessonSession);
@EXPORT_OK = qw(
);




=head1 DESCRIPTION

=head2 Public Methods

=head3 C<new Lesson($session)>

=cut

sub new {
	my $class = shift;
	my $session = shift;

	my $group;
	my $groupkind;
	my $id;

	my $q = $session->query();
        $group = $q->param('group');

	my $classs = Schulkonsole::Info::groups_classes($session->groups());
	if (    $group
	    and $$classs{$group}) {
		$session->param('group', $group);
		$session->param('groupkind', 'Klasse');
	}

	my $projects = Schulkonsole::Info::groups_projects($session->groups());
        if ( $group
            and $$projects{$group}) {
                $session->param('group', $group);
                $session->param('groupkind', 'Projekt');
        }
        
	$group = $session->param('group');
	$groupkind = $session->param('groupkind');

	return undef unless $group;



	$id = $session->userdata('id');

	my $this = new Schulkonsole::LessonSession($group,$groupkind);

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
		} elsif ($this->param('name') eq $group) {
			$is_allowed_stopedit = 2;
		}
	}

	$this->{_LESSONDATA} = {
		name => $group,
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

	return $this->{_LESSONDATA}{$key};
}




=head3 C<start_lesson()>

=cut

sub start_lesson {
	my $this = shift;
	my $id = shift;
	my $password = shift;

	if (not $this->{_LESSONDATA}{name}) {
		die new Schulkonsole::Error(Schulkonsole::Error::UNKNOWN_GROUP);
	}


	$this->{_LESSONDATA}{editing_userdata}
		= Schulkonsole::DB::get_userdata_by_id($this->{_LESSONDATA}{id});

	$this->{_LESSONDATA}{is_editing} = 1;
	$this->{_LESSONDATA}{is_allowed_stopedit} = 1;

	$this->param('name', $this->{_LESSONDATA}{name});
	$this->param('user_id', $this->{_LESSONDATA}{id});
	$this->param('edit', 1);

	$this->param('start_time',$^T);


	my $allowed_groups_wlan
		= Schulkonsole::Radius::allowed_groups_wlan();

	$this->param('oldsettings', {
		name => $this->param('name'),
		wlan_on => ($$allowed_groups_wlan{$this->param('name')}? 1 : 0),
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
	Schulkonsole::Radius::wlan_reset($id, $password, $this->{_LESSONDATA}{name});
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
	Schulkonsole::Radius::wlan_reset_at($id, $password,
		$this->{_LESSONDATA}{name},
		$end_time);
	$this->lock();
}




=head3 C<set_vars($session)>

Set template variables

=head4 Parameters

=over

=item C<$session>

The session to set the template variables

=back

=head4 Description

Sets template variables for this lesson:

=over

=item C<group>

Name of the group (class, subclass, project)

=item C<editinguser>

Name of user holding a lesson

=item C<edit>

True if someone is holding a lesson

=item C<stopedit>

True if the current user is allowed to stop the lesson

=item C<endedittime>

Time of lesson to end

=back

=cut

sub set_vars {
	my $this = shift;
	my $session = shift;

	$session->set_var('group', $this->info('name'));
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
                my $uid = $session->userdata('id');
                my $userdata = Schulkonsole::DB::get_userdata($uid);
                my @privileged_users;
                my $groups = Schulkonsole::DB::user_groups(
                        $$userdata{uidnumber},
                        $$userdata{gidnumber},
                        $$userdata{gid});
                my @groupnames = keys %$groups;
                foreach my $group (('ALL', @groupnames)) {
                        if ($$permissions{$group}{group_lesson}) {
                                push @privileged_users,
                                        "$$userdata{firstname} $$userdata{surname}";
                                last;
                        }
                }
                $session->set_var('privilegeduser', join(', ', @privileged_users));
	}

}


1;
