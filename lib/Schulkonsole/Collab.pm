use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Error;
use Schulkonsole::Config;


package Schulkonsole::Collab;

=head1 NAME

Schulkonsole::Collab - interface to Linuxmusterloesung DB and SVN commands

=head1 SYNOPSIS

 use Schulkonsole::Collab;

=head1 DESCRIPTION

Schulkonsole::Collab is an interface to the Linuxmusterloesung DB and SVN
commands used by schulkonsole.

If a wrapper command fails, it usually dies with a Schulkonsole::Error.
The output of the failed command is stored in the Schulkonsole::Error.

=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	create_db
	drop_db
	drop_db_user
	list_db
	list_db_user
	create_repository
	drop_repository
	list_repository
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
		$Schulkonsole::Config::_wrapper_collab
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_EXEC_FAILED,
			$Schulkonsole::Config::_wrapper_collab, $!);

	my $re = waitpid $pid, POSIX::WNOHANG;
	if (   $re == $pid
	    or $re == -1) {
		my $error = ($? >> 8) - 256;
		if ($error < -127) {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_EXEC_FAILED,
				$Schulkonsole::Config::_wrapper_collab, $!);
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_COLLAB_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_collab);
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
				$Schulkonsole::Config::_wrapper_collab, $!,
				($input_buffer ? "Output: $input_buffer" : 'No Output'));
		} else {
			die new Schulkonsole::Error(
				Schulkonsole::Error::WRAPPER_COLLAB_ERROR_BASE + $error,
				$Schulkonsole::Config::_wrapper_collab);
		}
	}

	close $out
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_OUT,
			$Schulkonsole::Config::_wrapper_collab, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));

	close $in
		or die new Schulkonsole::Error(
			Schulkonsole::Error::WRAPPER_BROKEN_PIPE_IN,
			$Schulkonsole::Config::_wrapper_collab, $!,
			($input_buffer ? "Output: $input_buffer" : 'No Output'));
	
	undef $input_buffer;
}




=head2 Functions

=head3 C<create_db($id, $password, $gid)>

Create a database

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$gid>

The GID to which the database belongs

=back

=head3 Description

This wraps the command
C<< linuxmuster-mysql --create --group=<gid> --teacher=<uid> >>, where
C<gid> is C<$gid> and C<uid> is the UID of the user with the ID C<$id>.

=cut

sub create_db {
	my $id = shift;
	my $password = shift;
	my $gid = shift;

	my $pid = start_wrapper(Schulkonsole::Config::CREATEDROPDBAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$gid\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head3 C<drop_db($id, $password, $gid)>

Delete a database

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$gid>

The GID to which the database belongs

=back

=head3 Description

This wraps the command
C<< linuxmuster-mysql --drop --group=<gid> --teacher=<uid> >>, where
C<gid> is C<$gid> and C<uid> is the UID of the user with the ID C<$id>.

=cut

sub drop_db {
	my $id = shift;
	my $password = shift;
	my $gid = shift;

	my $pid = start_wrapper(Schulkonsole::Config::CREATEDROPDBAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n$gid\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}





=head3 C<drop_db_user($id, $password, @dbs)>

Delete user's databases

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<@dbs>

Names of databases to delete

=back

=head3 Description

This wraps the command
C<< mysqladmin drop <db> >>, for each C<db> in C<@dbs>

=cut

sub drop_db_user {
	my $id = shift;
	my $password = shift;
	my @dbs = @_;

	my $pid = start_wrapper(Schulkonsole::Config::DROPDBUSERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	foreach my $db (@dbs) {
		print SCRIPTOUT "$db\n";
	}
	print SCRIPTOUT "\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}





=head3 C<list_db($id, $password, $gid)>

List databases

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$gid>

The GID to which the databases belong

=back

=head3 Return value

A reference to an array of databases

=head3 Description

This wraps the command
C<< linuxmuster-mysql --list --group=<gid> >>, where
C<gid> is C<$gid> and returns the result as a list of databases

=cut

sub list_db {
	my $id = shift;
	my $password = shift;
	my $gid = shift || '';

	my $pid = start_wrapper(Schulkonsole::Config::LISTDBAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$gid\n";

	my @re;
	while (<SCRIPTIN>) {
		chomp;
		push @re, $_;
	}

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);


	return \@re;
}





=head3 C<list_db_user($id, $password)>

List databases

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Return value

A reference to an array of databases

=head3 Description

This wraps the command
C<< linuxmuster-mysql --list --user=<uid> >>, where
C<uid> is the UID of the user with the ID C<$id>
and returns the result as a list of databases

=cut

sub list_db_user {
	my $id = shift;
	my $password = shift;

	my $pid = start_wrapper(Schulkonsole::Config::LISTDBUSERAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	my @re;
	while (<SCRIPTIN>) {
		chomp;
		push @re, $_;
	}

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);


	return \@re;
}





=head3 C<create_repository($id, $password, $gid)>

Create a repository

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$gid>

The GID to which the repository belongs

=back

=head3 Description

This wraps the command
C<< linuxmuster-svn --create --group=<gid> --teacher=<uid> >>, where
C<gid> is C<$gid> and C<uid> is the UID of the user with the ID C<$id>.

=cut

sub create_repository {
	my $id = shift;
	my $password = shift;
	my $gid = shift;

	my $pid = start_wrapper(Schulkonsole::Config::CREATEDROPREPOSITORYAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$gid\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head3 C<drop_repository($id, $password, $gid)>

Delete a repository

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$gid>

The GID to which the repository belongs

=back

=head3 Description

This wraps the command
C<< linuxmuster-svn --drop --group=<gid> --teacher=<uid> >>, where
C<gid> is C<$gid> and C<uid> is the UID of the user with the ID C<$id>.

=cut

sub drop_repository {
	my $id = shift;
	my $password = shift;
	my $gid = shift;

	my $pid = start_wrapper(Schulkonsole::Config::CREATEDROPREPOSITORYAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "0\n$gid\n";

	buffer_input(\*SCRIPTIN);

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);
}




=head3 C<list_repository($id, $password, $gid)>

Get a list of repositories

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$gid>

The GID to which the repositories belong

=back

=head3 Return value

A reference to an array of repositories

=head3 Description

This wraps the command
C<< linuxmuster-svn --list --group=<gid> >>, where
C<gid> is C<$gid> and returns the result as list of repositories

=cut

sub list_repository {
	my $id = shift;
	my $password = shift;
	my $gid = shift || '';

	my $pid = start_wrapper(Schulkonsole::Config::LISTREPOSITORYAPP,
		$id, $password,
		\*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);

	print SCRIPTOUT "1\n$gid\n";

	my @re;
	while (<SCRIPTIN>) {
		chomp;
		push @re, $_;
	}

	stop_wrapper($pid, \*SCRIPTOUT, \*SCRIPTIN, \*SCRIPTIN);


	return \@re;
}






1;
