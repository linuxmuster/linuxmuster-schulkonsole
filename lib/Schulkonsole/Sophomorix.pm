use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';

use Sophomorix::SophomorixConfig;
use Sophomorix::SophomorixAPI;

use Schulkonsole::Wrapper;
use Schulkonsole::Error::SophomorixError;
use Schulkonsole::Config;
use Safe;


package Schulkonsole::Sophomorix;

=head1 NAME

Schulkonsole::Sophomorix - interface to Sophomorix commands

=head1 SYNOPSIS

 use Schulkonsole::Sophomorix;
 use Schulkonsole::Session;

 my $session = new Schulkonsole::Session('file.cgi');
 my $id = $session->userdata('id');
 my $password = $session->get_password();


 my $files = Schulkonsole::Sophomorix::ls_handout_exam($id, $password);
 foreach my $file (@$files) {
 	print "$file\n";
 }

 $files = Schulkonsole::Sophomorix::ls_handoutcopy_current_room(
 	$id, $password);

 my @uids = ('user1', 'user2');
 Schulkonsole::Sophomorix::handoutcopy_from_room_to_users(
 	$id, $password, @uids);

 my $room = 'Dining-Room';
 $files = Schulkonsole::Sophomorix::ls_collect(
 	$id, $password, @login_ids);
 Schulkonsole::Sophomorix::collectcopy_from_room_users(
 	$id, $password, $room, @uids);
 Schulkonsole::Sophomorix::collect_from_room_users(
 	$id, $password, $room, @uids);

 Schulkonsole::Sophomorix::handout_from_room($id, $password, $room);

 Schulkonsole::Sophomorix::collectcopy_exam($id, $password, $room);
 Schulkonsole::Sophomorix::collect_exam($id, $password, $room);

 my @login_ids = (10, 13, 17);
 my $share_states = Schulkonsole::Sophomorix::share_states($id,
 	$password, @login_ids);

 if ($share_states{10}) {
 	print "shared directory of user #10 is activated\n";
 }


 Schulkonsole::Sophomorix::shares_on($id, $password, $login_ids);
 Schulkonsole::Sophomorix::shares_off($id, $password, $login_ids);

 Schulkonsole::Sophomorix::reset_room($id, $password, $room);

=head1 DESCRIPTION

Schulkonsole::Sophomorix is an interface to Sophomorix commands used
by schulkonsole. It also provides functions related to Sophomorix.
Namely commands to display the contents of Sophomorix directories.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.05;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	ls_handout_exam
	ls_handout_class
	ls_handout_project
	ls_handoutcopy_current_room
	ls_handoutcopy_class
	ls_handoutcopy_project
	ls_collect
	handout_from_room
	handout_class
	handout_project
	handoutcopy_from_room_to_users
	handoutcopy_from_class_to_users
	handoutcopy_from_project_to_users
	collect_from_room_users
	collect_from_class_users
	collect_from_project_users
	collectcopy_from_room_users
	collectcopy_from_class_users
	collectcopy_from_project_users
	collect_exam
	collectcopy_exam

	share_states
	shares_on
	shares_off
	reset_room
	add_to_class
	remove_from_class
	print_class
	print_teachers
	print_project
	global_shares_on
	global_shares_off

	passwords_random
	passwords_reset
	passwords_set

	www_set_user_permissions
	www_set_group_permissions
	www_set_global_permissions

	add_to_project
	remove_from_project
	remove_class_from_project
	remove_project_from_project
	create_project
	drop_project
	add_admin_to_project
	add_class_to_project
	add_project_to_project
	remove_admin_from_project
	set_project_joinable

	read_teachers_file
	read_students_file
	read_extra_user_file
	read_extra_course_file
	read_admin_report_file
	read_office_report_file
	read_add_log_file
	read_move_log_file
	read_kill_log_file
	write_teachers_file
	write_students_file
	write_extra_user_file
	write_extra_course_file
	write_sophomorix_conf
	write_quota_conf
	write_mailquota_conf
	list_add
	list_move
	list_kill

	users_check
	users_add
	users_move
	users_kill
	users_addmovekill
	teachin_check
	teachin_list
	teachin_set

	process_quota
	class_set_quota
	project_set_quota

	read_add_file
	read_kill_file
	read_move_file

	change_password

	hide_unhide_classes
	change_mailalias_classes
	change_maillist_classes
	change_mailalias_projects
	change_maillist_projects
);


my $wrapcmd = $Schulkonsole::Config::_wrapper_sophomorix;
my $errorclass = "Schulkonsole::Error::SophomorixError";

=head2 Functions

=head3 C<share_states($id, $password, @login_ids)>

Returns the states of shared directories

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@login_ids>

The IDs of the users of the shared directories.

=back

=head4 Return value

A reference to a hash of the form C<< $login_id => 0 | 1 >>, where C<$login_id>
is the ID of a user and the value is C<0> if her share is deactivated or
C<1> if it is activated.

=head4 Description

Returns the states of the Samba-shares of the users with the IDs C<@login_ids>.

=cut

sub share_states {
	my $id = shift;
	my $password = shift;
	my @login_ids = @_;

	return {} unless @login_ids;

	my %shares_infos;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::SHARESTATESAPP,
							$id, $password,
							join("\n", @login_ids)."\n\n");

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<share_on($id, $password, @login_ids)>

Turns Samba shares on

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@login_ids>

The IDs of the users of the shared directories.

=back

=head4 Description

Turns the Samba-shares of the users with the IDs C<@login_ids> on.

=cut

sub shares_on {
	my $id = shift;
	my $password = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SHARESONOFFAPP,
						$id, $password,
						"1\n", join("\n", @users), "\n\n");
}




=head3 C<share_off($id, $password, @login_ids)>

Turns Samba shares off

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@login_ids>

The IDs of the users of the shared directories.

=back

=head4 Description

Turns the Samba-shares of the users with the IDs C<@login_ids> off.

=cut

sub shares_off {
	my $id = shift;
	my $password = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SHARESONOFFAPP,
						$id, $password,
						"0\n", join("\n", @users), "\n\n");
}




=head3 C<global_shares_on($id, $password)>

Activate global shares

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Description

This activates the global shares

=cut

sub global_shares_on {
	my $id = shift;
	my $password = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHMODAPP,
						$id, $password,
						"0\n1\n");
}




=head3 C<global_shares_off($id, $password)>

Deactivate global shares

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Description

This deactivates the global shares

=cut

sub global_shares_off {
	my $id = shift;
	my $password = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHMODAPP,
						$id, $password,
						"0\n0\n");
}




=head3 C<add_handout_exam($id, $password, $filename, $isdir, $tmpfile)>

Add the filename to the handout directory of the current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the teacher's handout directory.

=cut

sub add_handout_exam {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
						$id, $password,
						"2\n0\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_handout_exam($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the handout directory of the current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the teacher's handout directory.

=cut

sub dl_handout_exam {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
						$id, $password,
						"3\n0\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_handout_exam($id, $password, $filename)>

Removes the filename from the handout directory of the current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the teacher's handout directory.

=cut

sub rm_handout_exam {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
						$id, $password,
						"1\n0\n1\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_handout_exam($id, $password)>

Returns the contents of the handout directory current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's handout directory, that will be
handed out with C<handout_exam()>.

=cut

sub ls_handout_exam {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"0\n1\n", 1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_handout_class($id, $password, $class, $filename, $isdir, $tmpfile)>

Add the filename to the handout directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class to add the handout to

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the class' handout directory.

=cut

sub add_handout_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
						$id, $password,
						"2\n0\n8\n$class\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");

}




=head3 C<dl_handout_class($id, $password, $class, $filename, $isdir, $tmpfile)>

Download the filename from the handout directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class to download the handout from

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the class' handout directory.

=cut

sub dl_handout_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
						$id, $password,
						"3\n0\n8\n$class\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");

}




=head3 C<rm_handout_class($id, $password, $filename)>

Removes the filename from the handout directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The name of the class

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the class' handout directory.

=cut

sub rm_handout_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
						$id, $password,
						"1\n0\n8\n$class\n$filename\n".($isdir?"1\n":"0\n"));

}




=head3 C<ls_handout_class($id, $password, $class)>

Returns the contents of the handout directory current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's handout directory, that will be
handed out with C<handout_class()>.

=cut

sub ls_handout_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"0\n8\n$class\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_handedout_myclass($id, $password, $teacher, $filename, $isdir, $tmpfile)>

Download the filename from the handedout directory of the students' class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$teacher>

The file owning teacher

=item C<$filename>

The name of the students file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the students class' handout directory.

=cut

sub dl_handedout_myclass {
	my $id = shift;
	my $password = shift;
	my $teacher = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n0\n8\n$teacher\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_handedoutcopy_myclass($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the handedoutcopy directory of the students' class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the students file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the students class' handedoutcopy directory.

=cut

sub dl_handedoutcopy_myclass {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n1\n8\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_handedout_myclass($id, $password, $filename)>

Removes the filename from the handedout directory of the students class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the students class' handedout directory.

=cut

sub rm_handedout_myclass {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n0\n8\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<rm_handedoutcopy_myclass($id, $password, $filename)>

Removes the filename from the handedoutcopy directory of the students class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the students class' handedoutcopy directory.

=cut

sub rm_handedoutcopy_myclass {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n1\n8\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_handedout_myclass($id, $password, $uid)>

Returns the contents of the handedout directory for the students class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$uid>

The uid of the student invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the students class handedout directory, that were
handed out with C<handout_class()>.

=cut

sub ls_handedout_myclass {
	my $id = shift;
	my $password = shift;
	my $uid = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"0\n8\n$uid\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<ls_handedoutcopy_myclass($id, $password)>

Returns the contents of the handedoutcopy directory for the students class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the students class handedoutcopy directory, that were
handed out with C<handoutcopy_class()>.

=cut

sub ls_handedoutcopy_myclass {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"1\n8\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_myclass_tocollect($id, $password, $filename, $isdir, $tmpfile)>

Add the filename to the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the students collect directory.

=cut

sub add_myclass_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"2\n2\n8\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_myclass_tocollect($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Downloads a file to the students collect directory.

=cut

sub dl_myclass_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n2\n8\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_myclass_tocollect($id, $password, $filename, $isdir)>

Remove the filename from the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the students' file to be removed

=item C<$isdir>

If the file to be removed is a directory (isdir == 1)

=back

=head4 Description

Remove a file from the students collect directory.

=cut

sub rm_myclass_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n2\n8\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_myclass_tocollect($id, $password)>

Returns the contents of the tocollect directory for the students' class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of files

=head4 Description

Returns a list of the files in the students class tocollect directory, that will
be collected with C<collect_class()>.

=cut

sub ls_myclass_tocollect {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"2\n8\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_handout_project($id, $password, $project, $filename, $isdir, $tmpfile)>

Add the filename to the handout directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project to add the handout to

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the project' handout directory.

=cut

sub add_handout_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"2\n0\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_handout_project($id, $password, $project, $filename, $isdir, $tmpfile)>

Download the filename from the handout directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project to download the handout from

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the project' handout directory.

=cut

sub dl_handout_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n0\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_handout_project($id, $password, $project, $filename)>

Removes the filename from the handout directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The name of the project

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the project' handout directory.

=cut

sub rm_handout_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n0\n4\n$project\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_handout_project($id, $password, $project)>

Returns the contents of the handout directory current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's handout directory, that will be
handed out with C<handout_project()>.

=cut

sub ls_handout_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"0\n4\n$project\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_handedout_myprojects($id, $password, $project, $teacher, $filename, $isdir, $tmpfile)>

Download the filename from the handedout directory of the students' projects

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$project>

The handedoutcopy directory of the students' projects

=item C<$teacher>

The teacher that handed out the file

=item C<$filename>

The name of the students file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the students class' handedout from the teachers subdirectory.

=cut

sub dl_handedout_myprojects {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $teacher = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n0\n4\n$project\n$teacher\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}



=head3 C<ls_handedout_myprojects($id, $password, $myproject)>

Returns the contents of the handedout directory for the students' project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the students' project handedout directory of myproject, that were
handed out with C<handoutcopy_project()>.

=cut

sub ls_handedout_myprojects {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"0\n4\n$project\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_handedoutcopy_myprojects($id, $password, $project, $filename, $isdir, $tmpfile)>

Download the filename from the handedoutcopy directory of the students' projects

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$project>

The handedoutcopy directory of the students' projects

=item C<$filename>

The name of the students file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the students class' handedoutcopy directory.

=cut

sub dl_handedoutcopy_myprojects {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n1\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}



=head3 C<rm_handedoutcopy_myprojects($id, $password, $project, $filename, $isdir, $tmpfile)>

Remove the filename from the handedoutcopy directory of the students' projects

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$project>

The handedoutcopy directory of the students' projects

=item C<$filename>

The name of the students file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the students class' handedoutcopy directory.

=cut

sub rm_handedoutcopy_myprojects {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n1\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}



=head3 C<ls_handedoutcopy_myprojects($id, $password, $myproject)>

Returns the contents of the handedoutcopy directory for the students' project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the students' project handedoutcopy directory of myproject, that were
handed out with C<handoutcopy_project()>.

=cut

sub ls_handedoutcopy_myprojects {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"1\n4\n$project\n", Schulkonsole::Wrapper::MODE_FILE);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_handoutcopy_current_room($id, $password, $filename, $isdir, $tmpfile)>

Add the filename to the handout directory of the current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the teacher's handout directory.

=cut

sub add_handoutcopy_current_room {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"2\n1\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_handoutcopy_current_room($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the handout directory of the current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be downloaded

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the teacher's handout directory.

=cut

sub dl_handoutcopy_current_room {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n1\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_handoutcopy_current_room($id, $password, $filename)>

Removes the filename from the handout directory of the current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the teacher's handout directory.

=cut

sub rm_handoutcopy_current_room {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n1\n1\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_handoutcopy_current_room($id, $password)>

Returns the contents of the handoutcopy directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's handoutcopy directory, that will
be handed out with C<handoutcopy_current_room()>.

=cut

sub ls_handoutcopy_current_room {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"1\n1\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_myroom_handedoutcopy($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the handedoutcopy directory of the students' current room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the students file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the students class' handedoutcopy directory.

=cut

sub dl_myroom_handedoutcopy {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n1\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_myroom_handedoutcopy($id, $password, $filename)>

Removes the filename from the handedoutcopy directory of the students current room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the students' current room handedoutcopy directory.

=cut

sub rm_myroom_handedoutcopy {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n1\n1\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_myroom_handedoutcopy($id, $password)>

Returns the contents of the handedoutcopy directory for the students' current room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the students current room handedoutcopy directory, that were
handed out with C<handoutcopy_room()>.

=cut

sub ls_myroom_handedoutcopy {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"1\n1\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_myroom_tocollect($id, $password, $filename, $isdir, $tmpfile)>

Add the filename to the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the students collect directory.

=cut

sub add_myroom_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"2\n2\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_myroom_tocollect($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Downloads a file to the students collect directory.

=cut

sub dl_myroom_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n2\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_myroom_tocollect($id, $password, $filename, $isdir)>

Remove the filename from the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the students' file to be removed

=item C<$isdir>

If the file to be removed is a directory (isdir == 1)

=back

=head4 Description

Remove a file from the students collect directory.

=cut

sub rm_myroom_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n2\n1\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_myroom_tocollect($id, $password)>

Returns the contents of the tocollect directory for the students' class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of files

=head4 Description

Returns a list of the files in the students class tocollect directory, that will
be collected with C<collect_class()>.

=cut

sub ls_myroom_tocollect {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"2\n1\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_handoutcopy_class($id, $password, $class, $filename, $isdir, $tmpfile)>

Add the filename to the handout directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class to add the handout to

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the class' handout directory.

=cut

sub add_handoutcopy_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"2\n1\n8\n$class\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_handoutcopy_class($id, $password, $class, $filename, $isdir, $tmpfile)>

Download the filename from the handout directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class to download the handout from

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the class' handout directory.

=cut

sub dl_handoutcopy_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n1\n8\n$class\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_handoutcopy_class($id, $password, $filename)>

Removes the filename from the handout directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The name of the class

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the class' handout directory.

=cut

sub rm_handoutcopy_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n1\n8\n$class\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_handoutcopy_class($id, $password, $class)>

Returns the contents of the handoutcopy directory for a class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's handoutcopy directory, that will
be handed out with C<handoutcopy_class()>.

=cut

sub ls_handoutcopy_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"1\n8\n$class\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_handoutcopy_project($id, $password, $project, $filename, $isdir, $tmpfile)>

Add the filename to the handout directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project to add the handout to

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the project' handout directory.

=cut

sub add_handoutcopy_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"2\n1\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_handoutcopy_project($id, $password, $project, $filename, $isdir, $tmpfile)>

Download the filename from the handout directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project to download the handout from

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the project' handout directory.

=cut

sub dl_handoutcopy_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n1\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_handoutcopy_project($id, $password, $project, $filename)>

Removes the filename from the handout directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The name of the project

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the project' handout directory.

=cut

sub rm_handoutcopy_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n1\n4\n$project\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_handoutcopy_project($id, $password, $project)>

Returns the contents of the handoutcopy directory for a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's handoutcopy directory, that will
be handed out with C<handoutcopy_project()>.

=cut

sub ls_handoutcopy_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"1\n4\n$project\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_collected_class($id, $password, $class, $filename, $isdir, $tmpfile)>

Download the filename from the collected directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class to download the collected from

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the class' collected directory.

=cut

sub dl_collected_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n2\n8\n$class\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_collected_class($id, $password, $filename)>

Removes the filename from the collected directory of the class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The name of the class

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the class' collected directory.

=cut

sub rm_collected_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n2\n8\n$class\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_collected_class($id, $password, $class)>

Returns the contents of the collected directory current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's collected directory.

=cut

sub ls_collected_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"2\n8\n$class\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_collected_project($id, $password, $project, $filename, $isdir, $tmpfile)>

Download the filename from the collected directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project to download the collected from

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the project' collected directory.

=cut

sub dl_collected_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n2\n4\n$project\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_collected_project($id, $password, $filename)>

Removes the filename from the collected directory of the project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The name of the project

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the project' collected directory.

=cut

sub rm_collected_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n2\n4\n$project\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_collected_project($id, $password, $project)>

Returns the contents of the collected directory current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's collected directory.

=cut

sub ls_collected_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"2\n4\n$project\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<add_myprojects_tocollect($id, $password, $filename, $isdir, $tmpfile)>

Add the filename to the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Adds a file to the students collect directory.

=cut

sub add_myprojects_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"2\n2\n4\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<dl_myprojects_tocollect($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the file to be downloaded

=item C<$isdir>

If the file to be downloaded is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to get the file data from

=back

=head4 Description

Downloads a file to the students collect directory.

=cut

sub dl_myprojects_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"3\n2\n4\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_myprojects_tocollect($id, $password, $filename, $isdir)>

Remove the filename from the students' collect directory

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$filename>

The name of the students' file to be removed

=item C<$isdir>

If the file to be removed is a directory (isdir == 1)

=back

=head4 Description

Remove a file from the students collect directory.

=cut

sub rm_myprojects_tocollect {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::STUDENTSFILEMANAPP,
		$id, $password,
		"1\n2\n4\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_myprojects_tocollect($id, $password)>

Returns the contents of the tocollect directory for the students' class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of files

=head4 Description

Returns a list of the files in the students class tocollect directory, that will
be collected with C<collect_class()>.

=cut

sub ls_myprojects_tocollect {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDEDOUTAPP,
						$id, $password,
						"2\n4\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_collected_exam($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the collected directory of the exam

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the exam' collected directory.

=cut

sub dl_collected_exam {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n2\n2\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_collected_exam($id, $password, $filename)>

Removes the filename from the collected directory of the exam

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the exam' collected directory.

=cut

sub rm_collected_exam {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n2\n2\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_collected_exam($id, $password)>

Returns the contents of the collected directory exam

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's collected directory.

=cut

sub ls_collected_exam {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"2\n2\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<dl_collected_current_room($id, $password, $filename, $isdir, $tmpfile)>

Download the filename from the collected directory of the current room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be added

=item C<$isdir>

If the file to be added is a directory (isdir == 1)

=item C<$tmpfile>

The temporary filename to put the file data to

=back

=head4 Description

Downloads a file from the current room' collected directory.

=cut

sub dl_collected_current_room {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	my $tmpfile = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"3\n2\n1\n$filename\n".($isdir?"1\n":"0\n") . "$tmpfile\n");
}




=head3 C<rm_collected_current_room($id, $password, $filename)>

Removes the filename from the collected directory of the current room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$filename>

The name of the teachers file to be deleted

=item C<$isdir>

If the file to be deleted is a directory (isdir == 1)

=back

=head4 Description

Removes a file from the current room' collected directory.

=cut

sub rm_collected_current_room {
	my $id = shift;
	my $password = shift;
	my $filename = shift;
	my $isdir = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::FILEMANAPP,
		$id, $password,
		"1\n2\n1\n$filename\n".($isdir?"1\n":"0\n"));
}




=head3 C<ls_collected_current_room($id, $password)>

Returns the contents of the collected directory current_room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

A reference to an array of the files

=head4 Description

Returns a list of the files in the teacher's collected directory.

=cut

sub ls_collected_current_room {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSHANDOUTAPP,
						$id, $password,
						"2\n1\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<ls_collect($id, $password, @login_ids)>

Returns the contents of collect directories

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@login_ids>

The IDs of the users of the collect directories.

=back

=head4 Return value

A reference to a hash with the ID of the user as key and a reference to an
array of the user's files in the collect directory as values.

=head4 Description

Returns the files that can be collected with the C<collect_...()>
and C<collectcopy_...()> functions.

=cut

sub ls_collect {
	my $id = shift;
	my $password = shift;
	my @login_ids = @_;

	return {} unless @login_ids;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSCOLLECTAPP,
						$id, $password,
						join("\n", @login_ids) . "\n\n",1);

	my $compartment = new Safe;

	return $compartment->reval($in);
}




=head3 C<create_file_list($files)>

Creates a list with file information

=head4 Parameters

=over

=item C<$files>

A hash with file information

=back

=head4 Return value

A reference to a list of hashes with file information. The keys of the
hashes are: name (the filename), isdir (true if file is a directory, false
otherwise).

=head4 Description

Returns a list with file information

=cut

sub create_file_list {
	my $files = shift;

	return [] unless $files;

	my @files;
	my @dirs;

	foreach my $file (sort { lc($a) cmp lc($b) } keys %$files) {
		if ($$files{$file} eq 'd') {
			push @dirs, { name => $file,
			              isdir => 1,
			            };
		} else {
			push @files, { name => $file,
			               isdir => 0,
			             };
		}
	}


	return [ @dirs, @files ];
}




=head3 C<create_category_file_list($files)>

Creates a list with file information ordered by categories

=head4 Parameters

=over

=item C<$files>

A hash of hashes with file information

=back

=head4 Return value

A reference to a list of hashes with file information. The keys of the
hashes are: category, name (the filename), 
isdir (true if file is a directory, false otherwise).

=head4 Description

Returns a list with file information

=cut

sub create_category_file_list {
	my $files = shift;

	return [] unless $files;

	my @files;

	foreach my $category (sort {lc($a) cmp lc($b) } keys %$files) {
		my $tfiles = $$files{$category};
		foreach my $file (sort { lc($a) cmp lc($b) } keys %$tfiles) {
			push @files, { category => $category, 
						   name => $file,
			               isdir => $$tfiles{$file} eq 'd' ? 1 : 0,
			             };
		}
	}

	return [ @files ];
}




=head3 C<create_subcat_file_list($files)>

Creates a list with file information ordered by categories/subcategories

=head4 Parameters

=over

=item C<$files>

A hash of hashes with file information

=back

=head4 Return value

A reference to a list of hashes with file information. The keys of the
hashes are: category, subcategory, name (the filename), 
isdir (true if file is a directory, false otherwise).

=head4 Description

Returns a list with file information

=cut

sub create_subcat_file_list {
	my $files = shift;

	return [] unless $files;

	my @files;

	foreach my $cat (sort {lc($a) cmp lc($b) } keys %$files) {
		my $catfiles = $$files{$cat};
		foreach my $subcat (sort { lc($a) cmp lc($b) } keys %$catfiles) {
			my $subcatfiles = $$catfiles{$subcat};
			foreach my $file (sort { lc($a) cmp lc($b) } keys %$subcatfiles) {
				push @files, { category => $cat,
					           subcategory => $subcat, 
							   name => $file,
				               isdir => $$subcatfiles{$file} eq 'd' ? 1 : 0,
				             };
			}
		}
	}

	return [ @files ];
}




=head3 C<handout_from_room($id, $password, $room)>

Hands out files to users in room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$room>

The room as defined in /etc/linuxmuster/classrooms

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --room room --handout>,
where uid is the UID of the teacher with ID C<$id> and
C<room> is C<$room>.

=cut

sub handout_from_room {
	my $id = shift;
	my $password = shift;
	my $room = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HANDOUTAPP,
		$id, $password,
		"0\n2\n$room\n");
}





=head3 C<handout_class($id, $password, $class)>

Hands out files to class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --class class --handout>,
where uid is the UID of the teacher with ID C<$id> and
C<class> is C<$class>.

=cut

sub handout_class {
	my $id = shift;
	my $password = shift;
	my $class = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HANDOUTAPP,
		$id, $password,
		"0\n8\n$class\n");
}





=head3 C<handout_project($id, $password, $project)>

Hands out files to project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --project project --handout>,
where uid is the UID of the teacher with ID C<$id> and
C<project> is C<$project>.

=cut

sub handout_project {
	my $id = shift;
	my $password = shift;
	my $project = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HANDOUTAPP,
		$id, $password,
		"0\n4\n$project\n");
}





=head3 C<handoutcopy_from_room_to_users($id, $password, @users)>

Hands out copies of files to users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --users user1,user2,... --fromroom
  --handoutcopy>, where uid is the UID of the teacher with ID C<$id> and
C<user1,user2,...> are the UIDs in C<@users>.

=cut

sub handoutcopy_from_room_to_users {
	my $id = shift;
	my $password = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HANDOUTAPP,
		$id, $password,
		"1\n1\n" . join("\n", @users) . "\n\n");
}




=head3 C<handoutcopy_from_class_to_users($id, $password, $class, @users)>

Hands out copies of files to users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --users user1,user2,... --fromclass class
  --handoutcopy>, where uid is the UID of the teacher with ID C<$id>,
class is C<$class> and C<user1,user2,...> are the UIDs in C<@users>.

=cut

sub handoutcopy_from_class_to_users {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HANDOUTAPP,
		$id, $password,
		"1\n8\n$class\n" . join("\n", @users) . "\n\n");
}




=head3 C<handoutcopy_from_project_to_users($id, $password, $project, @users)>

Hands out copies of files to users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --users user1,user2,... --fromproject project
  --handoutcopy>, where uid is the UID of the teacher with ID C<$id>,
project is C<$project> and C<user1,user2,...> are the UIDs in C<@users>.

=cut

sub handoutcopy_from_project_to_users {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HANDOUTAPP,
		$id, $password,
		"1\n4\n$project\n" . join("\n", @users) . "\n\n");
}




=head3 C<collect_from_room_users($id, $password, $room, @users)>

Collects files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$room>

The room as defined in /etc/linuxmuster/classrooms

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --users user1,user2,... --collect
--room room>, where uid is the UID of the teacher with ID C<$id>,
C<user1,user2,...> are the UIDs in C<@users>, and room is C<$room>.

=cut

sub collect_from_room_users {
	my $id = shift;
	my $password = shift;
	my $room = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"0\n0\n1\n" . join("\n", @users) . "\n\n");
}




=head3 C<collect_from_class_users($id, $password, $class, @users)>

Collects files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class as defined in /etc/linuxmuster/classclasss

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --users user1,user2,... --collect
--class class>, where uid is the UID of the teacher with ID C<$id>,
C<user1,user2,...> are the UIDs in C<@users>, and class is C<$class>.

=cut

sub collect_from_class_users {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"0\n0\n8\n$class\n" . join("\n", @users) . "\n\n");
}




=head3 C<collect_from_project_users($id, $password, $project, @users)>

Collects files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project as defined in /etc/linuxmuster/projectprojects

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --users user1,user2,... --collect
--project project>, where uid is the UID of the teacher with ID C<$id>,
C<user1,user2,...> are the UIDs in C<@users>, and project is C<$project>.

=cut

sub collect_from_project_users {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"0\n0\n4\n$project\n" . join("\n", @users) . "\n\n");
}




=head3 C<collectcopy_from_room_users($id, $password, $room, @users)>

Collects copies of files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$room>

The room as defined in /etc/linuxmuster/classrooms

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --room room --users user1,user2,...
--collectcopy>, where uid is the UID of the teacher with ID C<$id>,
C<user1,user2,...> are the UIDs in C<@users>, and room is C<$room>.

=cut

sub collectcopy_from_room_users {
	my $id = shift;
	my $password = shift;
	my $room = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"1\n0\n1\n" . join("\n", @users) . "\n\n");
}




=head3 C<collectcopy_from_class_users($id, $password, $class, @users)>

Collects copies of files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

The class

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --class class --users user1,user2,...
--collectcopy>, where uid is the UID of the teacher with ID C<$id>,
C<user1,user2,...> are the UIDs in C<@users>, and class is C<$class>.

=cut

sub collectcopy_from_class_users {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"1\n0\n8\n$class\n" . join("\n", @users) . "\n\n");
}




=head3 C<collectcopy_from_project_users($id, $password, $project, @users)>

Collects copies of files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

The project

=item C<@users>

The UIDs of the users

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --project project --users user1,user2,...
--collectcopy>, where uid is the UID of the teacher with ID C<$id>,
C<user1,user2,...> are the UIDs in C<@users>, and project is C<$project>.

=cut

sub collectcopy_from_project_users {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my @users = @_;

	return unless @users;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"1\n0\n4\n$project\n" . join("\n", @users) . "\n\n");
}




=head3 C<collect_exam($id, $password, $room)>

Collects exam files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$room>

The room where the exam takes place

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --room room --exam --collect>, where uid
is the UID of the teacher with ID C<$id> and room is C<$room>.

=cut

sub collect_exam {
	my $id = shift;
	my $password = shift;
	my $room = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"0\n1\n0\n2\n$room\n");
}




=head3 C<collectcopy_exam($id, $password, $room)>

Collects copies of exam files from users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$room>

The room where the exam takes place

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --room room --exam --collectcopy>, where
uid is the UID of the teacher with ID C<$id> and room is C<$room>.

=cut

sub collectcopy_exam {
	my $id = shift;
	my $password = shift;
	my $room = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::COLLECTAPP,
		$id, $password,
		"1\n1\n0\n2\n$room\n");
}




=head3 C<reset_room($id, $password, $room)>

Resets workstation accounts in a room

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$room>

The room as defined in /etc/linuxmuster/classrooms

=back

=head4 Description

This wraps the command
C<sophomorix-room --reset-room room>, where room is C<$room>.

=cut

sub reset_room {
	my $id = shift;
	my $password = shift;
	my $room = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::RESETROOMAPP,
		$id, $password,
		"$room\n");
}




=head3 C<add_to_class($id, $password, $class_gid)>

Adds a teacher to a class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class_gid>

The GID of the class

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --add class-gid>, where
uid is the UID of the teacher with ID C<$id> and class-gid is C<$class_gid>.

=cut

sub add_to_class {
	my $id = shift;
	my $password = shift;
	my $class_gid = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::EDITOWNCLASSMEMBERSHIPAPP,
		$id, $password,
		"$class_gid\n1\n");
}




=head3 C<remove_from_class($id, $password, $class_gid)>

Remove a teacher from a class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class_gid>

The GID of the class

=back

=head4 Description

This wraps the command
C<sophomorix-teacher --teacher uid --remove class-gid>, where
uid is the UID of the teacher with ID C<$id> and class-gid is C<$class_gid>.

=cut

sub remove_from_class {
	my $id = shift;
	my $password = shift;
	my $class_gid = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::EDITOWNCLASSMEMBERSHIPAPP,
		$id, $password,
		"$class_gid\n0\n");
}




=head3 C<print_class($id, $password, $class_gid)>

Return document with class info

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class_gid>

The GID of the class

=item C<$filetype>

Type of the file, either 0 (PDF) or 1 (CSV)

=back

=head4 Return value

PDF-data or CSV-data

=head4 Description

This wraps the command
C<sophomorix-print --class class-gid --postfix uid>, where
uid is the UID of the teacher with ID C<$id> and class-gid is C<$class_gid>
and returns the data of the produced document.

=cut

sub print_class {
	my $id = shift;
	my $password = shift;
	my $class_gid = shift;
	my $filetype = shift;

	my $data = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::PRINTCLASSAPP,
						$id, $password,
						"$class_gid\n$filetype\n",
						($filetype == 0 ? Schulkonsole::Wrapper::MODE_RAW : Schulkonsole::Wrapper::MODE_FILE));
	my $is_error = 0;
	if (    $filetype == 0
	    and $data !~ /^\%PDF/) {
		$is_error = 1;
#FIXME		$input_buffer = $data;
	}

	if ($is_error) {
		return undef;
	} else {
		return $data;
	}
}




=head3 C<ls_commits($id, $password)>

Returns the commit history of sophomorix

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=back

=head4 Return value

A reference to an array of commit dates

=head4 Description

Returns a list of the sophomorix commit dates (times).

=cut

sub ls_commits {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,  100001,#Schulkonsole::Config::LSCOMMITSAPP,
						$id, $password);
	my @ar = split('\R', $in);

	return \@ar;
}




=head3 C<ls_commit($id, $password, $commit)>

Returns the users that were added by this specific commit

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the student invoking the command

=item C<$password>

The password of the student invoking the command

=item C<$commit>

The specific commits' no.

=back

=head4 Return value

A reference to an array of uids

=head4 Description

Returns a list of the uids added by this commit.

=cut

sub ls_commit {
	my $id = shift;
	my $password = shift;
	my $commit = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::LSCOMMITAPP,
						$id, $password,
						"$commit\n");

	my @ar = split('\R', $in);

	return \@ar;
}




=head3 C<print_allusers($id, $password, $filetype, $one_per_page)>

Return document with all user info

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$filetype>

Type of the file, either 0 (PDF) or 1 (CSV)

=item C<$one_per_page>

For PDF print one user per page

=back

=head4 Return value

PDF-data or CSV-data

=head4 Description

This wraps the command
C<sophomorix-print --all --postfix uid>, where
uid is the UID of the user with ID C<$id>
and returns the data of the produced document.

=cut

sub print_allusers {
	my $id = shift;
	my $password = shift;
	my $filetype = shift;
	my $one_per_page = shift;
	
	my $data = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::PRINTALLUSERSAPP,
						$id, $password,
						"$filetype\n$one_per_page\n",
						($filetype == 0 ? Schulkonsole::Wrapper::MODE_RAW : Schulkonsole::Wrapper::MODE_FILE));

	my $is_error = 0;
	if (    $filetype == 0
	    and $data !~ /^\%PDF/) {
		$is_error = 1;
#FIXME		$input_buffer = $data;
	}
	if ($is_error) {
		return undef;
	} else {
		return $data;
	}
}




=head3 C<print_commit($id, $password, $commit, $filetype, $one_per_page)>

Return document with user info for specific commit

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$commit>

The no. of the specific commit

=item C<$filetype>

Type of the file, either 0 (PDF) or 1 (CSV)

=item C<$one_per_page>

For file type PDF print one user per page

=back

=head4 Return value

PDF-data or CSV-data

=head4 Description

This wraps the command
C<sophomorix-print --back-in-time commit --postfix uid>, where
uid is the UID of the user with ID C<$id> and commit is C<$commit>
and returns the data of the produced document.

=cut

sub print_commit {
	my $id = shift;
	my $password = shift;
	my $commit = shift;
	my $filetype = shift;
	my $one_per_page = shift;
	
	my $data = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::PRINTCOMMITAPP,
						$id, $password,
						"$commit\n$filetype\n$one_per_page\n",
						($filetype == 0 ? Schulkonsole::Wrapper::MODE_RAW : Schulkonsole::Wrapper::MODE_FILE));
	my $is_error = 0;
	if (    $filetype == 0
	    and $data !~ /^\%PDF/) {
		$is_error = 1;
#FIXME		$input_buffer = $data;
	}
	if ($is_error) {
		return undef;
	} else {
		return $data;
	}
}




=head3 C<print_teachers($id, $password, $class_gid)>

Return document with teachers info

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the administrator invoking the command

=item C<$password>

The password of the administratorr invoking the command

=item C<$filetype>

Type of the file, either 0 (PDF) or 1 (CSV)

=back

=head4 Return value

PDF-data or CSV-data

=head4 Description

This wraps the command
C<sophomorix-print --teacher>, where
uid is the UID of the teacher with ID C<$id> and class-gid is C<$class_gid>
and returns the data of the produced document.

=cut

sub print_teachers {
	my $id = shift;
	my $password = shift;
	my $filetype = shift;

	my $data = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::PRINTTEACHERSAPP,
						$id, $password,
						"$filetype\n",
						($filetype == 0 ? Schulkonsole::Wrapper::MODE_RAW : Schulkonsole::Wrapper::MODE_FILE));

	my $is_error = 0;
	if (    $filetype == 0
	    and $data !~ /^\%PDF/) {
		$is_error = 1;
#FIXME		$input_buffer = $data;
	}
	if ($is_error) {
		return undef;
	} else {
		return $data;
	}
}




=head3 C<print_project($id, $password, $project_gid)>

Return document with project info

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<$filetype>

Type of the file, either 0 (PDF) or 1 (CSV)

=back

=head4 Return value

PDF-data or CSV-data

=head4 Description

This wraps the command
C<sophomorix-print --project project-gid --postfix uid>, where
uid is the UID of the teacher with ID C<$id> and project-gid is C<$project_gid>
and returns the data of the produced document.

=cut

sub print_project {
        my $id = shift;
        my $password = shift;
        my $project_gid = shift;
        my $filetype = shift;

        my $data = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::PRINTPROJECTAPP,
						$id, $password,
						"$project_gid\n$filetype\n",
						($filetype == 0 ? Schulkonsole::Wrapper::MODE_RAW : Schulkonsole::Wrapper::MODE_FILE));

        my $is_error = 0;
        if (    $filetype == 0
            and $data !~ /^\%PDF/) {
                $is_error = 1;
#FIXME                $input_buffer = $data;
        }
        if ($is_error) {
                return undef;
        } else {
                return $data;
        }
}




=head3 C<passwords_reset($id, $password, @users)>

Reset users' passwords

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@users>

The users' UIDs

=back

=head4 Description

This wraps the command
C<sophomorix-passwd --hide --reset --users user1,user2,...>, where
C<user1,user2,...> are the UIDs passed in C<@users>.

=cut

sub passwords_reset {
	my $id = shift;
	my $password = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETPASSWORDSAPP,
		$id, $password,
		"0\n0\n" . join("\n", @users) . "\n\n");
}




=head3 C<passwords_random($id, $password, @users)>

Set random passwords for users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<@users>

The users' UIDs

=back

=head4 Description

This wraps the command
C<sophomorix-passwd --hide --random --users user1,user2,...>, where
C<user1,user2,...> are the UIDs passed in C<@users>.

=cut

sub passwords_random {
	my $id = shift;
	my $password = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETPASSWORDSAPP,
		$id, $password,
		"2\n0\n" . join("\n", @users) . "\n\n");
}




=head3 C<passwords_set($id, $password, $user_password, @users)>

Set users' passwords

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$user_password>

The users' new password

=item C<@users>

The users' UIDs

=back

=head4 Description

This wraps the command
C<sophomorix-passwd --hide --passwd password --users user1,user2,...>, where
C<user1,user2,...> are the UIDs passed in C<@users> and C<password> is
C<$user_password>.

=cut

sub passwords_set {
	my $id = shift;
	my $password = shift;
	my $user_password = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETPASSWORDSAPP,
		$id, $password,
		"1\n0\n$user_password\n" . join("\n", @users) . "\n\n");
}




=head3 C<www_set_user_permissions($id, $password, $is_public, $is_upload, @users)>

Set access permissions to users' WWW directories

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$is_public>

1 if directory is to be public, 0 otherwise

=item C<$is_upload>

1 if user is allowed to upload to directory, 0 otherwise

=item C<@users>

The users' UIDs

=back

=head4 Description

This wraps the command
C<sophomorix-www --student-public-upload user1,user2,...>,
C<sophomorix-www --student-public-noupload user1,user2,...>,
C<sophomorix-www --student-private-upload user1,user2,...>,
C<sophomorix-www --student-private-noupload user1,user2,...>,
where
C<user1,user2,...> are the UIDs passed in C<@users> and the option
parameter depends on C<$is_public> and C<$is_upload> as expected.

=cut

sub www_set_user_permissions {
	my $id = shift;
	my $password = shift;
	my $is_public = shift;
	my $is_upload = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::WWWPERMISSIONSAPP,
		$id, $password,
		"1\n$is_public\n$is_upload\n" . join("\n", @users) . "\n\n");
}




=head3 C<www_set_group_permissions($id, $password, $is_public, $is_upload)>

Set access permissions to groups WWW directories

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$is_public>

1 if directory is to be public, 0 otherwise

=item C<$is_upload>

1 if group is allowed to upload to directory, 0 otherwise

=item C<$gid>

The groups' GID

=back

=head4 Description

This wraps the command
C<sophomorix-www --group-public-upload group>,
C<sophomorix-www --group-public-noupload group>,
C<sophomorix-www --group-private-upload group>,
C<sophomorix-www --group-private-noupload group>,
where
C<group> is C<$gid> and the option
parameter depends on C<$is_public> and C<$is_upload> as expected.

=cut

sub www_set_group_permissions {
	my $id = shift;
	my $password = shift;
	my $is_public = shift;
	my $is_upload = shift;
	my $group = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::WWWPERMISSIONSAPP,
		$id, $password,
		"0\n$is_public\n$is_upload\n$group\n\n");
}




=head3 C<www_set_global_permissions($id, $password, $on)>

Set the access permissions to WWW

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=item C<$on>

1 to allow access, 0 otherwise

=back

=head4 Description

This sets the permissions of the WWW-directory

=cut

sub www_set_global_permissions {
	my $id = shift;
	my $password = shift;
	my $on = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHMODAPP,
		$id, $password,
		"1\n$on\n");
}




=head3 C<add_to_project($id, $password, $project_gid, @users)>

Adds a user to a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@users>

The users to be added

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --addmembers user1,user2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<user1,user2,...> are the UIDs passed in C<@users>
and project-gid is C<$project_gid>.

=cut

sub add_to_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n1\n0\n" . join("\n", @users) . "\n\n");
}





=head3 C<remove_from_project($id, $password, $project_gid, @users)>

Remove a user from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@users>

The users to be removed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --removemembers user1,user2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<user1,user2,...> are the UIDs passed in C<@users>
and project-gid is C<$project_gid>.

=cut

sub remove_from_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n0\n0\n" . join("\n", @users) . "\n\n");
}




=head3 C<add_admin_to_project($id, $password, $project_gid, @users)>

Adds admins to a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@users>

The users to be added

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --addadmins user1,user2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<user1,user2,...> are the UIDs passed in C<@users>
and project-gid is C<$project_gid>.

=cut

sub add_admin_to_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n1\n1\n" . join("\n", @users) . "\n\n");
}




=head3 C<remove_admin_from_project($id, $password, $project_gid, @users)>

Removes admins from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@users>

The users to be removed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --removeadmins user1,user2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<user1,user2,...> are the UIDs passed in C<@users>
and project-gid is C<$project_gid>.

=cut

sub remove_admin_from_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @users = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n0\n1\n" . join("\n", @users) . "\n\n");
}




=head3 C<set_project_joinable($id, $password, $project_gid, $is_join)>

Removes admins from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<$is_join>

True if the project is to be joinable

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --project project-gid [--join|--nojoin]>,
where
caller is the UID of the user with the ID C<$id>,
project-gid is C<$project_gid>
and C<--join>/C<--nojoin> is used if C<$is_join> is true/false

=cut

sub set_project_joinable {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my $is_join = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTJOINNOJOINAPP,
		$id, $password,
		($is_join ? "$project_gid\n\n\n" : "\n$project_gid\n\n"));
}




=head3 C<add_class_to_project($id, $password, $project_gid, @users)>

Remove a class from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@groups>

The classes to be removed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --addmembergroups group1,group2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<group1,group2,...> are the GIDs passed in C<@groups>
and project-gid is C<$project_gid>.

=cut

sub add_class_to_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @groups = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n1\n2\n" . join("\n", @groups) . "\n\n");
}




=head3 C<remove_class_from_project($id, $password, $project_gid, @users)>

Remove a class from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@groups>

The classes to be removed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --removemembergroups group1,group2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<group1,group2,...> are the GIDs passed in C<@groups>
and project-gid is C<$project_gid>.

=cut

sub remove_class_from_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @groups = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n0\n2\n" . join("\n", @groups) . "\n\n");
}




=head3 C<add_project_to_project($id, $password, $project_gid, @users)>

Remove a project from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@groups>

The groups to be removed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --removememberprojects group1,group2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<group1,group2,...> are the GIDs passed in C<@groups>
and project-gid is C<$project_gid>.

=cut

sub add_project_to_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @groups = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n1\n3\n" . join("\n", @groups) . "\n\n");
}




=head3 C<remove_project_from_project($id, $password, $project_gid, @users)>

Remove a project from a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<@groups>

The groups to be removed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --removememberprojects group1,group2 --project project-gid>,
where
caller is the UID of the user with the ID C<$id>,
C<group1,group2,...> are the GIDs passed in C<@groups>
and project-gid is C<$project_gid>.

=cut

sub remove_project_from_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my @groups = @_;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTMEMBERSAPP,
		$id, $password,
		"$project_gid\n0\n3\n" . join("\n", @groups) . "\n\n");
}




=head3 C<create_project($id, $password, $project_gid, $is_open)>

Create a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=item C<$is_open>

True if the user list of the project can be changed

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --project project-gid --create --admins uid [--join|--nojoin]>,
where
caller is the UID of the user with the ID C<$id>,
project-gid is C<$project_gid>,
uid is the UID of the user with the ID C<$id>,
and the option C<--join>/C<--nojoin> is used if C<$is_open> is true/false.

=cut

sub create_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;
	my $is_open = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTCREATEDROPAPP,
		$id, $password,
		"$project_gid\n1\n" . ($is_open ? 1 : 0) . "\n");
}




=head3 C<drop_project($id, $password, $project_gid)>

Drop a project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project_gid>

The GID of the project

=back

=head4 Description

This wraps the command
C<sophomorix-project --caller caller --project project-gid --kill>,
where
caller is the UID of the user with the ID C<$id>,
project-gid is C<$project_gid>.

=cut

sub drop_project {
	my $id = shift;
	my $password = shift;
	my $project_gid = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::PROJECTCREATEDROPAPP,
		$id, $password,
		"$project_gid\n0\n");
}




sub read_file {
	my $id = shift;
	my $password = shift;
	my $file_number = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::READSOPHOMORIXFILEAPP,
						$id, $password,
						"$file_number\n");

	my @re = split('\R', $in);

	return \@re;
}




=head3 C<read_teachers_file($id, $password)>

Read the lehrer.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/etc/sophomorix/user/lehrer.txt

=head4 Description

Reads the file /etc/sophomorix/user/lehrer.txt

=cut

sub read_teachers_file {
	return read_file(@_, 0);
}




=head3 C<read_students_file($id, $password)>

Read the schueler.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/etc/sophomorix/user/schueler.txt

=head4 Description

Reads the file /etc/sophomorix/user/schueler.txt

=cut

sub read_students_file {
	return read_file(@_, 1);
}




=head3 C<read_extra_user_file($id, $password)>

Read the extraschueler.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/etc/sophomorix/user/extraschueler.txt

=head4 Description

Reads the file /etc/sophomorix/user/extraschueler.txt

=cut

sub read_extra_user_file {
	return read_file(@_, 10);
}




=head3 C<read_extra_course_file($id, $password)>

Read the extrakurse.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/etc/sophomorix/user/extrakurse.txt

=head4 Description

Reads the file /etc/sophomorix/user/extrakurse.txt

=cut

sub read_extra_course_file {
	return read_file(@_, 11);
}




=head3 C<read_add_file($id, $password)>

Read sophomorix.add file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/var/lib/sophomorix/check-result/sophomorix.add

=head4 Description

Reads the file /var/lib/sophomorix/check-result/sophomorix.add

=cut

sub read_add_file {
	return read_file(@_, 2);
}




=head3 C<read_move_file($id, $password)>

Read the sophomorix.move file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/var/lib/sophomorix/check-result/sophomorix.move

=head4 Description

Reads the file /var/lib/sophomorix/check-result/sophomorix.move

=cut

sub read_move_file {
	return read_file(@_, 3);
}




=head3 C<read_kill_file($id, $password)>

Read the sophomorix.kill file

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/var/lib/sophomorix/check-result/sophomorix.kill

=head4 Description

Reads the file /var/lib/sophomorix/check-result/sophomorix.kill

=cut

sub read_kill_file {
	return read_file(@_, 4);
}




=head3 C<read_admin_report_file($id, $password)>

Read /var/lib/sophomorix/check-result/report.admin

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/var/lib/sophomorix/check-result/report.admin

=head4 Description

Reads the file /var/lib/sophomorix/check-result/report.admin

=cut

sub read_admin_report_file {
	return read_file(@_, 5);
}




=head3 C<read_office_report_file($id, $password)>

Read /var/lib/sophomorix/check-result/report.office

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the file
/var/lib/sophomorix/check-result/report.office

=head4 Description

Reads the file /var/lib/sophomorix/check-result/report.office

=cut

sub read_office_report_file {
	return read_file(@_, 6);
}




=head3 C<read_add_log_file($id, $password)>

Read last of sophomorix.add.txt.* log files

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the log file

=head4 Description

Reads the last file of the sorted list of
/var/log/sophomorix/sophomorix.add.txt.* log files, i.e. the newest.

=cut

sub read_add_log_file {
	return read_file(@_, 7);
}




=head3 C<read_move_log_file($id, $password)>

Read last of sophomorix.move.txt.* log files

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the log file

=head4 Description

Reads the last file of the sorted list of
/var/log/sophomorix/sophomorix.move.txt.* log files, i.e. the newest.

=cut

sub read_move_log_file {
	return read_file(@_, 8);
}




=head3 C<read_kill_log_file($id, $password)>

Read last of sophomorix.kill.txt.* log files

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the log file

=head4 Description

Reads the last file of the sorted list of
/var/log/sophomorix/sophomorix.kill.txt.* log files, i.e. the newest.

=cut

sub read_kill_log_file {
	return read_file(@_, 9);
}




sub write_file {
	my $id = shift;
	my $password = shift;
	my $lines = shift;
	my $file_number = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::WRITESOPHOMORIXFILEAPP,
		$id, $password,
		"$file_number\n" . join('', @$lines));
}




=head3 C<write_teachers_file($id, $password, $lines)>

Write new lehrer.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/lehrer.txt and backups the old
file

=cut

sub write_teachers_file {
	write_file(@_, 0);
}




=head3 C<write_students_file($id, $password, $lines)>

Write new schueler.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/schueler.txt and backups the old
file

=cut

sub write_students_file {
	write_file(@_, 1);
}




=head3 C<write_extra_user_file($id, $password, $lines)>

Write new extraschueler.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/extraschueler.txt and backups the old
file

=cut

sub write_extra_user_file {
	write_file(@_, 5);
}




=head3 C<write_extra_course_file($id, $password, $lines)>

Write new extrakurse.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/extrakurse.txt and backups the old
file

=cut

sub write_extra_course_file {
	write_file(@_, 6);
}




=head3 C<write_sophomorix_conf($id, $password, $lines)>

Write new sophomorix.conf

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/sophomorix.conf and backups the old
file

=cut

sub write_sophomorix_conf {
	write_file(@_, 2);
}




=head3 C<write_quota_conf($id, $password, $lines)>

Write new quota.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/quota.txt and backups the old
file

=cut

sub write_quota_conf {
	write_file(@_, 3);
}




=head3 C<write_mailquota_conf($id, $password, $lines)>

Write new mailquota.txt

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$lines>

The lines of the new file

=back

=head4 Description

Writes the file /etc/sophomorix/user/mailquota.txt and backups the old
file

=cut

sub write_mailquota_conf {
	write_file(@_, 4);
}




=head3 C<list_add($id, $password)>

Get the list of users to be added

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of hashes with the following keys:
identifier, group

=head4 Description

Reads the file /var/lib/sophomorix/check-result/sophomorix.add and return
a list with the users

=cut

sub list_add {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::READSOPHOMORIXFILEAPP,
						$id, $password,
						"2\n");

	my @re;
	while (split('\R', $in)) {
		my ($group, $identifier) = split '::';
		if (not $identifier) {
			die new Schulkonsole::Error(Schulkonsole::Error::FILE_FORMAT_ERROR,
				'sophomorix.add', $in);
		}

		push @re, {
				identifier => $identifier,
				group => $group,
			};
	}

	return \@re;
}




=head3 C<list_move($id, $password)>

Get the list of users to be moved

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of hashes with the following keys:
login, from, to, status

=head4 Description

Reads the file /var/lib/sophomorix/check-result/sophomorix.move and return
a list with the users

=cut

sub list_move {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::READSOPHOMORIXFILEAPP,
						$id, $password,
						"3\n");

	my @re;
	while (split('\R', $in)) {
		my ($login, $from, $to, $status) = split '::';
		if (not $to) {
			die new Schulkonsole::Error(Schulkonsole::Error::FILE_FORMAT_ERROR,
				'sophomorix.move', $in);
		}

		push @re, {
				login => $login,
				from => $from,
				to => $to,
				status => $status,
			};
	}

	return \@re;
}




=head3 C<list_kill($id, $password)>

Get the list of users to be removed

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of hashes with the following keys:
login, identifier

=head4 Description

Reads the file /var/lib/sophomorix/check-result/sophomorix.move and return
a list with the users

=cut

sub list_kill {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::READSOPHOMORIXFILEAPP,
						$id, $password,
						"4\n");

	my @re;
	while (split('\R', $in)) {
		my ($identifier, $login) = split '::';
		if (not $login) {
			die new Schulkonsole::Error(Schulkonsole::Error::FILE_FORMAT_ERROR,
				'sophomorix.move', $in);
		}

		push @re, {
				login => $login,
				identifier => $identifier
			};
	}

	return \@re;
}




=head3 C<users_check($id, $password)>

Check syntax of user input files

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

The output of C<sophomorix-check>

=head4 Description

This wraps the command C<sophomorix-check> and returns the output

=cut

sub users_check {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::USERSCHECKAPP,
						$id, $password);
	
	return $in;
}




=head3 C<users_add($id, $password)>

Add users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

The name of the log file

=head4 Description

This wraps the command C<sophomorix-add>

=cut

sub users_add {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::USERSADDAPP,
						$id, $password);
		
	chomp $in;
	return $in;
}




=head3 C<users_move($id, $password)>

Move users to next class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

The name of the log file

=head4 Description

This wraps the command C<sophomorix-move>

=cut

sub users_move {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::USERSMOVEAPP,
						$id, $password);
	
	chomp $in;
	return $in;
}




=head3 C<users_kill($id, $password)>

Delete users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

The name of the log file

=head4 Description

This wraps the command C<sophomorix-kill>

=cut

sub users_kill {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::USERSKILLAPP,
						$id, $password);
	
	chomp $in;
	return $in;
}




=head3 C<users_addmovekill($id, $password)>

Add users, move users to other class and delete users

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Description

This wraps the commands C<sophomorix-add>, C<sophomorix-move>, and
C<sophomorix-kill>

=cut

sub users_addmovekill {
	my $id = shift;
	my $password = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::USERSADDMOVEKILLAPP,
		$id, $password);
}




=head3 C<teachin_check($id, $password)>

Check if teach-in is necessary

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

True if teach-in is necessary, false otherwise

=head4 Description

This uses the command C<sophomorix-teach-in --next 1> to check if a teach-in
is necessary

=cut

sub teachin_check {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::TEACHINAPP,
						$id, $password,
						"0\n");

	my $re = 0;
	while (split('\R', $in)) {
		if (/^next::/) {
			my @values = split '::';
			if (@values > 5) {
				$re = 1;
				last;
			}
		}
	}

	return $re;
}




=head3 C<teachin_list($id, $password)>

Get the list for teach-in

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head4 Return value

A hash with usernames as keys and as value a reference to a hash
{ id => "identifier of the user",
  class => "class of the user",
  alt => { identifier of possible alternative => { class => "class of alt" },
           [...]
		 }
}

=head4 Description

This wraps the command C<sophomorix-teach-in --all> to get the teach-in-list.

=cut

sub teachin_list {
	my $id = shift;
	my $password = shift;

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd,$errorclass,Schulkonsole::Config::TEACHINAPP,
						$id, $password,
						"1\n");

	my %re;
	while ($in) {
		if (/^next::/) {
			my (@values) = split '::';
			shift @values;	# "next"
			my $class= shift @values;
			my $uid = shift @values;
			my $id = shift @values;

			$re{$uid}{id} = $id;
			$re{$uid}{class} = $class;

			if (@values > 1) {
				while (@values > 1) {
					my $alt_class = shift @values;
					my $alt_id = shift @values;

					$re{$uid}{alt}{$alt_id}{class} = $alt_class;
				}
			}
		}
	}

	return \%re;
}




=head3 C<teachin_set($id, $password, $users)>

Does the teach-in

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$users>

A reference to a hash with usernames as keys and as value a reference to a hash
{ selected => $identifier}, where C<$identifier> is the identifier of the
new user associated with this username

=back

=head4 Description

This wraps the command
C<sophomorix-teach-in --teach-in user1::identifier1,user2::identifier2,...>,
with userX, and identifierX being the corresponding values from C<$users>.

=cut

sub teachin_set {
	my $id = shift;
	my $password = shift;
	my $users = shift;

	return unless %$users;

	my $output;
	foreach my $username (keys %$users) {
		$output .= "$username\t$$users{$username}{selected}\n";
	}
	$output .= "\n";

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::TEACHINAPP,
						$id, $password,
						"2\n$output");
}




=head3 C<process_quota($id, $password, $scope)>

Processes the changes in quota

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$scope>

bitwise or: 1 = set quota,
2 = set quota for teachers,
4 = set quota for students

=back

=head4 Description

This wraps the command
C<sophomorix-quota [--set] [--teachers] [--students]> and uses the options
corresponding to C<$scope>

=cut

sub process_quota {
	my $id = shift;
	my $password = shift;
	my $scope = shift;

	return unless $scope;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETQUOTAAPP,
		$id, $password,
		"$scope\n");
}




=head3 C<class_set_quota($id, $password, $gid, $diskquota, $mailquota)>

Set quotas for class

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$class>

name of the class

=item C<diskquota>

diskquotas separated with '+' or undef

=item C<mailquota>

mailquota or undef

=back

=head4 Description

This wraps the commands
C<sophomorix-class --class name --quota diskquota --mailquota mailquota>,
where name is C<$class>, diskquota is C<$diskquota> and mailquota is
C<mailquota>.

=cut

sub class_set_quota {
	my $id = shift;
	my $password = shift;
	my $class = shift;
	my $diskquota = shift;
	my $mailquota = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETQUOTAAPP,
		$id, $password,
		"16\n$class\n$diskquota\n$mailquota\n");
}




=head3 C<project_set_quota($id, $password, $gid, $diskquota, $mailquota)>

Set quotas for project

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$project>

name of the project

=item C<diskquota>

diskquotas separated with '+' or undef

=item C<mailquota>

mailquota or undef

=back

=head4 Description

This wraps the commands
C<sophomorix-project --caller caller --project name --quota diskquota --mailquota mailquota>,
where
caller is the UID of the user with the ID C<$id>,
name is C<$project>, diskquota is C<$diskquota> and mailquota is
C<mailquota>.

=cut

sub project_set_quota {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	my $diskquota = shift;
	my $mailquota = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETQUOTAAPP,
		$id, $password,
		"17\n$project\n$diskquota\n$mailquota\n");
}




=head3 C<change_password($id, $password, $newpassword)>

Set password

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$newpassword>

new password

=back

=head4 Description

This wraps the commands
C<sophomorix-passwd --user uid --pass password>,
where uid is the UID of the user with the ID C<$id> and password is
C<newpassword>.

=cut

sub change_password {
	my $id = shift;
	my $password = shift;
	my $newpassword = shift;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETOWNPASSWORDAPP,
		$id, $password,
		"$newpassword\n");
}




=head3 C<change_room_password($id, $password, $newpassword)>

Set password

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$newpassword>

new password

=item C<@rooms>

The rooms where the workstations' passwords are to be set

=back

=head4 Description

This wraps the command
C<sophomorix-passwd --room room1,room2,... --pass password>,
where room1,room2,... is the rooms in C<@rooms> and password is
C<$newpassword>.

=cut

sub change_room_password {
	my $id = shift;
	my $password = shift;
	my $newpassword = shift;
	my @rooms = @_;


	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETPASSWORDSAPP,
		$id, $password,
		"1\n1\n$newpassword\n" . join("\n", @rooms) . "\n\n");
}






=head3 C<hide_unhide_classes($id, $password, $hide_classs, unhide_classs)>

Hide/unhide classes

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$hide_classs>

A reference to an array of GIDs of classes to hide

=item C<$unhide_classs>

A reference to an array of GIDs of classes to un-hide

=back

=head4 Description

This wraps the command
C<sophomorix-class --class GID --hide> for all GIDs in C<$hide_classs>
and the command
C<sophomorix-class --class GID --unhide> for all GIDs in C<$unhide_classs>

=cut

sub hide_unhide_classes {
	my $id = shift;
	my $password = shift;
	my $hide_classs = shift;
	my $unhide_classs = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::HIDEUNHIDECLASSAPP,
		$id, $password,
      	(@$hide_classs ? join("\n", @$hide_classs) . "\n\n" : "\n") .
	    (@$unhide_classs ? join("\n", @$unhide_classs) . "\n\n" : "\n"));
}


=head3 C<set_user_mymail($id,$password,$mymail)>

Set users private mail address

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$mymail>

The string containing the mail address (can be empty)

=back

=head4 Description

This wraps the subroutine DB::set_user_myail($uid,$mymail).

=cut

sub set_user_mymail {
	my $id = shift;
	my $password = shift;
	my $mymail = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::SETMYMAILAPP,
						$id, $password,
						"$mymail\n\n");

}

=head3 C<change_mailalias_classes($id, $password, $create_mailalias_classs, remove_mailalias_classs)>

Create/Remove mailaliases for classes

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$create_mailalias_classs>

A reference to an array of GIDs of classes to create mailaliases

=item C<$remove_mailalias_classs>

A reference to an array of GIDs of classes to remove mailaliases

=back

=head4 Description

This wraps the command
C<sophomorix-class --class GID --mailalias> for all GIDs in C<$create_mailalias_classs>
and the command
C<sophomorix-class --class GID --nomailalias> for all GIDs in C<$remove_mailalias_classs>

=cut

sub change_mailalias_classes {
	my $id = shift;
	my $password = shift;
	my $create_mailalias_classs = shift;
	my $remove_mailalias_classs = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHANGEMAILALIASCLASSAPP,
		$id, $password,
	    (@$create_mailalias_classs ? join("\n", @$create_mailalias_classs) . "\n\n" : "\n") .
	    (@$remove_mailalias_classs ? join("\n", @$remove_mailalias_classs) . "\n\n" : "\n"));
}


=head3 C<change_maillist_classes($id, $password, $create_maillist_classs, remove_maillist_classs)>

Create/Remove maillists for classes

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$create_maillist_classs>

A reference to an array of GIDs of classes to create mailaliases

=item C<$remove_maillist_classs>

A reference to an array of GIDs of classes to remove mailaliases

=back

=head4 Description

This wraps the command
C<sophomorix-class --class GID --maillist> for all GIDs in C<$create_maillist_classs>
and the command
C<sophomorix-class --class GID --nomaillists> for all GIDs in C<$remove_maillist_classs>

=cut

sub change_maillist_classes {
	my $id = shift;
	my $password = shift;
	my $create_maillist_classs = shift;
	my $remove_maillist_classs = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHANGEMAILLISTCLASSAPP,
		$id, $password,
	    (@$create_maillist_classs ? join("\n", @$create_maillist_classs) . "\n\n" : "\n") .
	    (@$remove_maillist_classs ? join("\n", @$remove_maillist_classs) . "\n\n" : "\n"));
}


=head3 C<change_mailalias_projects($id, $password, $create_mailalias_projects, remove_mailalias_projects)>

Create/Remove mailaliases for projects

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$create_mailalias_projects>

A reference to an array of GIDs of projects to create mailaliases

=item C<$remove_mailalias_projects>

A reference to an array of GIDs of projects to remove mailaliases

=back

=head4 Description

This wraps the command
C<sophomorix-project --project GID --mailalias> for all GIDs in C<$create_mailalias_projects>
and the command
C<sophomorix-project --project GID --nomailalias> for all GIDs in C<$remove_mailalias_projects>

=cut

sub change_mailalias_projects {
	my $id = shift;
	my $password = shift;
	my $create_mailalias_projects = shift;
	my $remove_mailalias_projects = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHANGEMAILALIASPROJECTAPP,
		$id, $password,
        (@$create_mailalias_projects ? join("\n", @$create_mailalias_projects) . "\n\n" : "\n") .
	    (@$remove_mailalias_projects ? join("\n", @$remove_mailalias_projects) . "\n\n" : "\n"));
}


=head3 C<change_maillist_projects($id, $password, $create_maillist_projects, remove_maillist_projects)>

Create/Remove maillists for projects

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$create_maillist_projects>

A reference to an array of GIDs of projects to create mailaliases

=item C<$remove_maillist_projects>

A reference to an array of GIDs of projects to remove mailaliases

=back

=head4 Description

This wraps the command
C<sophomorix-project --project GID --maillist> for all GIDs in C<$create_maillist_projects>
and the command
C<sophomorix-project --project GID --nomaillists> for all GIDs in C<$remove_maillist_projects>

=cut

sub change_maillist_projects {
	my $id = shift;
	my $password = shift;
	my $create_maillist_projects = shift;
	my $remove_maillist_projects = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd,$errorclass,Schulkonsole::Config::CHANGEMAILLISTPROJECTAPP,
		$id, $password,
	    (@$create_maillist_projects ? join("\n", @$create_maillist_projects) . "\n\n" : "\n") .
	    (@$remove_maillist_projects ? join("\n", @$remove_maillist_projects) . "\n\n" : "\n"));
}







1;
