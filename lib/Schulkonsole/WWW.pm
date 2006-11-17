use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Sophomorix::SophomorixAPI;
use Sophomorix::SophomorixConfig;
use Schulkonsole::Error;
use Schulkonsole::Config;
use Schulkonsole::Sophomorix;


package Schulkonsole::WWW;

=head1 NAME

 Schulkonsole::WWW - interface to Linuxmusterloesung WWW commands

=head1 SYNOPSIS

 use Schulkonsole::WWW;

=head1 DESCRIPTION

Schulkonsole::WWW provides commands to examine and change access permissions
to the LML web directories.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.04;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	student_permissions
	teacher_permissions
	class_permissions
	project_permissions
	set_user_permissions
	set_group_permissions
	set_www_on
	set_www_off
);




sub get_permissions {
	my $dir = shift;
	my %re;

	open HTACCESS, "<$dir/$Schulkonsole::Config::_htaccess_filename"
		or die new Schulkonsole::Error(Schulkonsole::Error::CANNOT_OPEN_FILE,
			"$dir/$Schulkonsole::Config::_htaccess_filename", $!);

	while (<HTACCESS>) {
		last unless /^#/;

		if (/^#\s*public/) {
			$re{public} = 1;
		} elsif (/^#\s*private/) {
			$re{public} = 0;
		} elsif (/^#\s*upload/) {
			$re{upload} = 1;
		} elsif (/^#\s*noupload/) {
			$re{upload} = 0;
		}
	}

	close HTACCESS;


	return \%re;
}



=head2 Functions

=head3 C<student_permissions(@students)>

Get the access permissions to students' WWW directories

=head3 Parameters

=over

=item C<@students>

The students' UIDs

=back

=head3 Return value

A hash with the students's UID as key and a hash reference of the form
C<{ public => 0|1, upload => 0|1 }> as a value.

=head3 Description

Examines the access permissions to the WWW directories of students of a class
and returns the result

=cut

sub student_permissions {
	my @students = @_;
	my %re;

	foreach my $student (@students) {
		eval {
		$re{$student}
			= get_permissions("$DevelConf::www_students/$student");
		};
		if ($@)  {
			print STDERR "$@\n";
			$re{$student}{public} = 0;
			$re{$student}{upload} = 0;
		}
	}


	return \%re;
}




=head2 Functions

=head3 C<teacher_permissions(@students)>

Get the access permissions to teachers' WWW directories

=head3 Parameters

=over

=item C<@teachers>

The teachers' UIDs

=back

=head3 Return value

A hash with the teachers's UID as key and a hash reference of the form
C<{ public => 0|1, upload => 0|1 }> as a value.

=head3 Description

Examines the access permissions to the WWW directories of teachers of a class
and returns the result

=cut

sub teacher_permissions {
	my @teachers = @_;
	my %re;

	foreach my $teacher (@teachers) {
		eval {
		$re{$teacher}
			= get_permissions("$DevelConf::www_teachers/$teacher");
		};
		if ($@)  {
			$re{$teacher}{public} = 0;
			$re{$teacher}{upload} = 0;
		}
	}


	return \%re;
}




=head3 C<class_permissions(@classs)>

Get the access permissions to classs' WWW directories

=head3 Parameters

=over

=item C<@classs>

The classs' UIDs

=back

=head3 Return value

A hash with the classs's UID as key and a hash reference of the form
C<{ public => 0|1, upload => 0|1 }> as a value.

=head3 Description

Examines the access permissions to the WWW directories of a class
and returns the result

=cut

sub class_permissions {
	my @classs = @_;
	my %re;

	foreach my $class (@classs) {
		eval {
		$re{$class}
			= get_permissions("$DevelConf::www_classes/$class");
		};
		if ($@)  {
			$re{$class}{public} = 0;
			$re{$class}{upload} = 0;
		}
	}


	return \%re;
}




=head3 C<project_permissions(@projects)>

Get the access permissions to projects' WWW directories

=head3 Parameters

=over

=item C<@projects>

The projects' UIDs

=back

=head3 Return value

A hash with the projects's UID as key and a hash reference of the form
C<{ public => 0|1, upload => 0|1 }> as a value.

=head3 Description

Examines the access permissions to the WWW directories of projects
and returns the result

=cut

sub project_permissions {
	my @projects = @_;
	my %re;

	foreach my $project (@projects) {
		eval {
		$re{$project}
			= get_permissions("$DevelConf::www_projects/$project");
		};
		if ($@)  {
			$re{$project}{public} = 0;
			$re{$project}{upload} = 0;
		}
	}


	return \%re;
}




=head3 C<set_user_permissions($id, $password, $is_public, $is_upload, @users)>

Set the access permissions to users' WWW directories

=head3 Parameters

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

=head3 Description

Sets the access permissions to users' WWW directories.

=cut

sub set_user_permissions {
	my $id = shift;
	my $password = shift;
	my $is_public = shift;
	my $is_upload = shift;
	my @users = @_;

	Schulkonsole::Sophomorix::www_set_user_permissions(
		$id, $password,
		$is_public, $is_upload,
		@users);
}




=head3 C<set_group_permissions($id, $password, $is_public, $is_upload, @groups)>

Set the access permissions to groups' WWW directories

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=item C<$is_public>

1 if directory is to be public, 0 otherwise

=item C<$is_upload>

1 if group is allowed to upload to directory, 0 otherwise

=item C<@groups>

The groups' UIDs

=back

=head3 Description

Sets the access permissions to groups' WWW directories.

=cut

sub set_group_permissions {
	my $id = shift;
	my $password = shift;
	my $is_public = shift;
	my $is_upload = shift;
	my @groups = @_;

	Schulkonsole::Sophomorix::www_set_group_permissions(
		$id, $password,
		$is_public, $is_upload,
		@groups);
}




=head3 C<set_www_on()>

Allow access to WWW directories

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head3 Description

Sets the permissions to allow access to the WWW directories.

=cut

sub set_www_on {
	my $id = shift;
	my $password = shift;

	Schulkonsole::Sophomorix::www_set_global_permissions(
		$id, $password,
		1);
}




=head3 C<set_www_off()>

Deny access to WWW directories

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the teacher invoking the command

=item C<$password>

The password of the teacher invoking the command

=back

=head3 Description

Sets the permissions to deny access to the WWW directories.

=cut

sub set_www_off {
	my $id = shift;
	my $password = shift;

	Schulkonsole::Sophomorix::www_set_global_permissions(
		$id, $password,
		0);
}







1;
