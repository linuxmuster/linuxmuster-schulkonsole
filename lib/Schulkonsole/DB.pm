use strict;
use DBI;
use Crypt::PasswdMD5;
use Crypt::SmbHash;
use Digest::MD5;
use Digest::SHA1;
use MIME::Base64;
use Schulkonsole::Error;
use Schulkonsole::Config;


=head1 NAME

Schulkonsole::DB - database access for schulkonsole

=head1 SYNOPSIS

 my $username = 'user';
 my $password = '{CRYPT}LMneiZPmGaKWA';
 my $userdata = verify_password($username, $password);

 if ($userdata) {
     print "password verified\n";
 }

 my $groups = user_groups($$userdata{uidnumber},
                          $$userdata{gidnumber}, $$userdata{gid});
 my @groupnames = keys %$groups;

 my $projects = groups_projects($groups);
 my @projectnames = keys %$projects;

 my $classes = groups_classes($groups);
 my @classnames = keys %$classes;

=head1 DESCRIPTION

On load the module connects with the database as the user C<Username> with
the password C<Password> and the database source name C<DSN> defined in
the configuration file db.conf.

=head2 Functions

=cut

package Schulkonsole::DB;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	get_userdata
	get_userdata_by_id
	verify_password
	verify_password_by_id
	user_groups
	groups_projects
	groups_classes

	classes
	all_classes
	get_classdata
	get_class_userdatas
	projects
	get_projectdata
	is_project_admin
	project_admins
	project_user_members
	project_class_members
	project_project_members
	get_teachers
	find_teachers
	find_students
	find_classes
	find_projects

	reconnect
);

my $_dbh;

my $_select_userdata = 'SELECT * FROM userdata ';
my $_select_basic_userdata = 'SELECT userdata.id AS id,
	userdata.uidnumber AS uidnumber,
	userdata.uid AS uid,
	userdata.gidnumber AS gidnumber,
	userdata.gid AS gid,
	userdata.firstname AS firstname,
	userdata.surname AS surname
	FROM userdata ';
my $_select_basic_classdata = 'SELECT classdata.id AS id,
	classdata.gid AS gid,
	classdata.gidnumber AS gidnumber,
	classdata.displayname AS displayname
	FROM classdata ';
my $_where_userdata_uid = 'WHERE uid = ?';
my $_where_userdata_gid = 'WHERE gid = ?';
my $_where_userdata_id = 'WHERE id = ?';




sub get_userdata {
	my $uid = shift;

	my $sth = $_dbh->prepare($_select_userdata . $_where_userdata_uid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$_select_userdata . $_where_userdata_uid);
	$sth->execute($uid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$_select_userdata . $_where_userdata_uid, "[uid = $uid]");

	my $re = $sth->fetchrow_hashref;
	$sth->finish;

	return $re;
}




sub get_userdata_by_id {
	my $id = shift;

	my $sth = $_dbh->prepare($_select_userdata . $_where_userdata_id)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$_select_userdata . $_where_userdata_id);
	$sth->execute($id)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$_select_userdata . $_where_userdata_id, "[id = $id]");

	my $re = $sth->fetchrow_hashref;
	$sth->finish;

	return $re;
}




sub verify_password_by_userdata {
	my $userdata = shift;
	my $password = shift;


	if ($userdata) {
		my $userpassword = $$userdata{userpassword};

		SWITCH: {
		$userpassword =~ s/^\{CRYPT\}//i and do {
			if (crypt($password, $userpassword) eq $userpassword) {
				return $userdata;
			}
			last SWITCH;
		};
		$userpassword =~ s/^\{SMD5\}//i and do {
			my ($salt) = $userpassword =~ /^\$1\$(.+?)\$/;

			if (Crypt::PasswdMD5::unix_md5_crypt($password, $salt)
			    	eq $userpassword) {
				return $userdata;
			}
			last SWITCH;
		};
		$userpassword =~ s/^\{MD5\}//i and do {
			if (Digest::MD5::md5_base64($password) eq $userpassword) {
				return $userdata;
			}
			last SWITCH;
		};
		$userpassword =~ s/^\{SSHA\}//i and do {
			my ($salt) = substring(decode_base64($userpassword), 20);

			if (encode_base64(
				Digest::SHA1::sha1($password . $salt, "") . $salt))
				eq $userpassword {
				return $userdata;
			}
			last SWITCH;
		};
		my $error = new Schulkonsole::Error(
			Schulkonsole::Error::UNKNOWN_PASSWORD_ENCRYPTION,
				$$userdata{uid});
		print STDERR "$error\n";
		}
	}

	return undef;
}




=head3 C<verify_password($username, $password)>

Verifies a user's password

=head4 Parameters

=over

=item C<$username>

The user's uid

=item C<$password>

The user's password

=back

=head4 Description

Verifies that the password C<$password> matches the encoded entry of the
user with uid C<$username> in the database.

=cut

sub verify_password {
	my $username = shift;
	my $password = shift;

	return verify_password_by_userdata(get_userdata($username), $password);
}




=head3 C<verify_password($id, $password)>

Verifies a user's password

=head4 Parameters

=over

=item C<$id>

The user's id in the database

=item C<$password>

The user's password

=back

=head4 Description

Verifies that the password C<$password> matches the encoded entry of the
user with id C<$id> in the database.

=cut

sub verify_password_by_id {
	my $id = shift;
	my $password = shift;

	return verify_password_by_userdata(get_userdata_by_id($id), $password);
}




sub salt {
	my $len = shift;
	my $re;

	my @chrs = ('a' .. 'z', 'A' .. 'Z', '.', '/');

	for (my $i = 0; $i < $len; $i++) {
		$re .= $chrs[int(rand $#chrs + 1)];
	}


	return $re;
}




=head3 C<user_groups($uidnumber, $initial_login_gidnumber, $initial_login_gid)>

Returns a user's groups

=head4 Parameters

=over

=item C<$uidnumber>

The user's numerical uid

=item C<$initial_login_gidnumber>

The numerical gid of the user's initial group

=item C<$initial_login_gid>

The numerical gid of the user's initial group

=back

=head4 Description

Returns the groups of the user with the numerical uid C<$uidnumber> in a
reference to a hash with the groupnames as keys and the numerical gids as
values.
The pair C<$initial_login_gid> => C<$initial_login_gidnumber> is a member of
this hash.

=cut

sub user_groups {
	my $memberuidnumber = shift;
	my $initial_login_gidnumber = shift;
	my $initial_login_gid = shift;
	my %groups = ( $initial_login_gid => $initial_login_gidnumber );

	my $prepare_user_groups = '
		SELECT groups.gid, groups.gidnumber
		FROM groups JOIN groups_users
		              ON groups_users.gidnumber = groups.gidnumber
		WHERE    groups_users.memberuidnumber = ?';
	my $sth = $_dbh->prepare($prepare_user_groups)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_user_groups);
	$sth->execute($memberuidnumber)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_user_groups, "[memberuidnumber = $memberuidnumber]");

	while (my ($group, $gidnumber) = $sth->fetchrow_array) {
		$groups{$group} = $gidnumber;
	}


	return \%groups;
}




=head3 C<groups_projects($groups)>

Returns a user's projects

=head4 Parameters

=over

=item C<$groups>

A reference to a hash as returned by C<user_groups()>

=back

=head4 Description

Returns the projects assigned with the groups in C<$groups> as a
reference to a hash with the project names as keys and the project data as
values.

=cut

sub groups_projects {
	my $groups = shift;
	my %projects;

	my @group_gidnumbers = values %$groups;
	my $gidnumber_where = 'gidnumber = '
		. join(' OR gidnumber = ', @group_gidnumbers);

	my $prepare_projectdata =
		'SELECT * FROM projectdata WHERE ' . $gidnumber_where;
	my $sth = $_dbh->prepare($prepare_projectdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projectdata);
	$sth->execute
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projectdata);

	while (my $row = $sth->fetchrow_hashref) {
		$projects{$$row{gid}} = $row;
	}


	return \%projects;
}




=head3 C<groups_classes($groups)>

Returns a user's classes

=head4 Parameters

=over

=item C<$groups>

A reference to a hash as returned by C<user_groups()>

=back

=head4 Description

Returns the classes assigned with the groups in C<$groups> as a
reference to a hash with the class names as keys and the class data as
values.

=cut

sub groups_classes {
	my $groups = shift;
	my %classs;

	my @group_gidnumbers = values %$groups;
	my $gidnumber_where = 'gidnumber = '
		. join(' OR gidnumber = ', @group_gidnumbers);

	my $prepare_classdata =
		'SELECT * FROM classdata WHERE type = \'adminclass\' AND ('
			. $gidnumber_where . ')';
	my $sth = $_dbh->prepare($prepare_classdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_classdata);
	$sth->execute
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_classdata);

	while (my $row = $sth->fetchrow_hashref) {
		$classs{$$row{gid}} = $row;
	}


	return \%classs;
}




=head3 C<classes()>

Returns all visible classes

=head4 Description

Returns all visible classes as a
reference to a hash with the class GIDs as keys and the class data as
values.

=cut

sub classes {
	my %classs;

	my $prepare_classdata
		= 'SELECT * FROM classdata WHERE type = \'adminclass\'';
	my $sth = $_dbh->prepare($prepare_classdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_classdata);
	$sth->execute
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_classdata);

	while (my $row = $sth->fetchrow_hashref) {
		$classs{$$row{gid}} = $row;
	}


	return \%classs;
}




=head3 C<all_classes()>

Returns all classes

=head4 Description

Returns all visible and hidden classes as a
reference to a hash with the class GIDs as keys and the class data as
values.

=cut

sub all_classes {
	my %classs;

	my $prepare_classdata
		=   'SELECT * FROM classdata '
		  . 'WHERE type = \'adminclass\' OR type = \'hiddenclass\'';
	my $sth = $_dbh->prepare($prepare_classdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_classdata);
	$sth->execute
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_classdata);

	while (my $row = $sth->fetchrow_hashref) {
		$classs{$$row{gid}} = $row;
	}


	return \%classs;
}




=head3 C<get_classdata()>

Returns classdata

=head4 Parameters

=over

=item C<$class>

The GID of the class

=back

=head4 Description

Returns the classdata of the class C<$class>.

=cut

sub get_classdata {
	my $class = shift;


	my $prepare_classdata = 'SELECT * FROM classdata '
		. 'WHERE     gid = ?'
		.      ' AND type = \'adminclass\'';
	my $sth = $_dbh->prepare($prepare_classdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_classdata);
	$sth->execute($class)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_classdata, "[gid = $class]");

	my $row = $sth->fetchrow_hashref;
	$sth->finish;


	return $row;

}




=head3 C<get_class_userdatas($gid)>

Returns userdatas of members of class

=head4 Parameters

=over

=item C<$gid>

The GID of the class

=back

=head4 Return value

A reference to a hash with the users' GID as key and the userdata as
values.

=head4 Description

Returns the userdatas of the members of class C<$gid>.

=cut

sub get_class_userdatas {
	my $gid = shift;

	my $sth = $_dbh->prepare($_select_userdata . $_where_userdata_gid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$_select_userdata . $_where_userdata_gid);
	$sth->execute($gid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$_select_userdata . $_where_userdata_gid, "[gid = $gid]");

	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{uid}} = $row;
	}

	return \%re;
}




=head3 C<projects()>

Returns all projects

=head4 Description

Returns all projects as a
reference to a hash with the project names as keys and the project data as
values.

=cut

sub projects {
	my %projects;

	my $prepare_projectdata
		= 'SELECT * FROM projectdata';
	my $sth = $_dbh->prepare($prepare_projectdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projectdata);
	$sth->execute
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projectdata);

	while (my $row = $sth->fetchrow_hashref) {
		$projects{$$row{gid}} = $row;
	}


	return \%projects;
}




=head3 C<get_projectdata()>

Returns projectdata

=head4 Parameters

=over

=item C<$project>

The GID of the project

=back

=head4 Description

Returns the projectdata of the project C<$project>.

=cut

sub get_projectdata {
	my $project = shift;


	my $prepare_projectdata = 'SELECT * FROM projectdata WHERE gid = ?';
	my $sth = $_dbh->prepare($prepare_projectdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projectdata);
	$sth->execute($project)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projectdata, "[gid = $project]");

	my $row = $sth->fetchrow_hashref;
	$sth->finish;


	return $row;

}




=head3 C<is_project_admin($projectid, $uidnumber)>

Returns if a user is admin of a project

=head4 Parameters

=over

=item C<$projectid>

ID of the project

=item C<uidnumber>

numeric UID of the user

=back

=head4 Return value

-1 if the user is the last admin of the project,
otherwise
1 if the user is an admin of the project,
0 if the user is not an admin of the project

=head4 Description

Returns if the user with the UID-number $uidnumber is an admin of
the project with ID $projectid.

=cut

sub is_project_admin {
	my $projectid = shift;
	my $uidnumber = shift;


	my $prepare_projects_admins
		= 'SELECT uidnumber FROM projects_admins WHERE projectid = ?';
	my $sth = $_dbh->prepare($prepare_projects_admins)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projects_admins);
	$sth->execute($projectid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projects_admins,
			"[projectid = $projectid]");

	my $cnt = 0;
	my $is_admin = 0;
	while (my $row = $sth->fetchrow_hashref) {
		$cnt++;
		if ($$row{uidnumber} == $uidnumber) {
			$is_admin = 1;
			if ($cnt > 1) {
				$sth->finish;
				last;
			}
		} else {
			last if $is_admin;
		}
	}

	if ($is_admin) {
		if ($cnt > 1) {
			return 1;
		} else {
			return -1;
		}
	}

	return 0;
}




=head3 C<project_admins($projectid)>

Returns admins of a project

=head4 Parameters

=over

=item C<$projectid>

ID of the project

=back

=head4 Return value

A reference to hash with the uidnumbers of the admins as key

=head4 Description

Returns the UID-numbers of the admins of the project with ID C<$projectid>.

=cut

sub project_admins {
	my $projectid = shift;


	my $prepare_projects_admins
		= 'SELECT uidnumber FROM projects_admins WHERE projectid = ?';
	my $sth = $_dbh->prepare($prepare_projects_admins)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projects_admins);
	$sth->execute($projectid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projects_admins,
			"[projectid = $projectid]");

	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{uidnumber}} = 1;
	}


	return \%re;
}




=head3 C<project_user_members($projectgid)>

Returns user members of a project

=head4 Parameters

=over

=item C<$projectgid>

GID of the project

=back

=head4 Return value

A reference to a hash with a UID as key and userdata as value

=head4 Description

Returns the userdatas of the user members of the project with
GID C<$projectgid>.

=cut

sub project_user_members {
	my $projectgid = shift;


	my $prepare_groups_users = $_select_basic_userdata .
	   'JOIN    groups_users
		     ON userdata.uidnumber = groups_users.memberuidnumber
		WHERE groups_users.gidnumber = ?';
	my $sth = $_dbh->prepare($prepare_groups_users)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_groups_users);
	$sth->execute($projectgid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_groups_users,
			"[gidnumber = $projectgid]");

	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{uid}} = $row;
	}


	return \%re;
}



=head3 C<project_class_members($projectid)>

Returns class members of a project

=head4 Parameters

=over

=item C<$projectid>

ID of the project

=back

=head4 Return value

A reference to a hash with the GID of the class as key and the classdata
as value

=head4 Description

Returns the classdata of the class members of the project with
ID C<$projectid>.

=cut

sub project_class_members {
	my $projectid = shift;


	my $prepare_classdata = $_select_basic_classdata
		. 'JOIN project_groups'
		. '  ON classdata.gidnumber = project_groups.membergid '
		. 'WHERE project_groups.projectid = ?';
	my $sth = $_dbh->prepare($prepare_classdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_classdata);
	$sth->execute($projectid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_classdata,
			"[projectid = $projectid]");

	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{gid}} = $row;
	}


	return \%re;
}




=head3 C<project_project_members($projectid)>

Returns project members of a project

=head4 Parameters

=over

=item C<$projectid>

ID of the project

=back

=head4 Return value

A reference to an array of gidnumbers

=head4 Description

Returns the GID-numbers of the project members of the project with
ID C<$projectid>.

=cut

sub project_project_members {
	my $projectid = shift;


	my $prepare_projectdata
		= 'SELECT projectdata.id AS id,
		          projectdata.gid AS gid,
		          projectdata.gidnumber AS gidnumber,
		          projectdata.displayname AS displayname,
		          projectdata.longname AS longname,
				  projectdata.addquota AS addquota
		   FROM projectdata
		   JOIN projects_memberprojects
		     ON projectdata.id = projects_memberprojects.memberprojectid
		   WHERE projects_memberprojects.projectid = ?';
	my $sth = $_dbh->prepare($prepare_projectdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projectdata);
	$sth->execute($projectid)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projectdata,
			"[projectid = $projectid]");

	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{gid}} = $row;
	}


	return \%re;
}




=head3 C<get_teachers($query)>

Returns teachers

=head4 Return value

A reference to a hash with UIDs as key and userdata as value

=head4 Description

Returns all users with the initial group 'teacher'

=cut

sub get_teachers {

	my $prepare_userdata = $_select_userdata
		. 'WHERE gid = \'teachers\'';
	my $sth = $_dbh->prepare($prepare_userdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_userdata);
	$sth->execute
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_userdata);


	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{uid}} = $row;
	}



	return \%re;
}




=head3 C<find_teachers($query)>

Returns teachers

=head4 Parameters

=over

=item C<$query>

A query to match teachers

=back

=head4 Return value

A reference to a hash with UIDs as key and userdata as value

=head4 Description

Returns the teachers on which the pattern of query matches.

=cut

sub find_teachers {
	my $query = shift;

	$query =~ tr/*/%/;
	my $pattern = "\%\L$query\E\%";

	my $prepare_userdata = $_select_basic_userdata
		. 'WHERE gid = \'teachers\' '
		. 'AND (   uid LIKE ?'
		.     ' OR LOWER(firstname) LIKE ?'
		.     ' OR LOWER(surname) LIKE ?)';
	my $sth = $_dbh->prepare($prepare_userdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_userdata);
	$sth->execute($pattern, $pattern, $pattern)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_userdata,
			"[uid LIKE $pattern, firstname LIKE $pattern, surname LIKE $pattern]");


	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{uid}} = $row;
	}


	$prepare_userdata = $_select_basic_userdata
		. 'JOIN groups_users'
		. '  ON userdata.uidnumber = groups_users.memberuidnumber '
		. 'JOIN groups'
		. '  ON groups_users.gidnumber = groups.gidnumber '
		. 'WHERE groups.gid = \'teachers\' '
		. 'AND (   userdata.uid LIKE ?'
		.     ' OR LOWER(userdata.firstname) LIKE ?'
		.     ' OR LOWER(userdata.surname) LIKE ?)';
	$sth = $_dbh->prepare($prepare_userdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_userdata);
	$sth->execute($pattern, $pattern, $pattern)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_userdata,
			"[uid LIKE $pattern, firstname LIKE $pattern, surname LIKE $pattern]");

	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{uid}} = $row;
	}



	return \%re;
}




=head3 C<find_students($query)>

Returns students

=head4 Parameters

=over

=item C<$query>

A query to match students

=back

=head4 Return value

A reference to a hash with UIDs as key and userdata as value

=head4 Description

Returns the students on which the pattern of query matches.

=cut

sub find_students {
	my $query = shift;

	$query =~ tr/*/%/;
	my $pattern = "\%\L$query\E\%";

	# a student's initial group is an adminclass
	my $prepare_userdata = $_select_basic_userdata
		. 'RIGHT JOIN classdata ON userdata.gidnumber = classdata.gidnumber '
		. 'WHERE classdata.type = \'adminclass\' '
		. 'AND (   userdata.uid LIKE ?'
		.     ' OR LOWER(userdata.firstname) LIKE ?'
		.     ' OR LOWER(userdata.surname) LIKE ?)';
	my $sth = $_dbh->prepare($prepare_userdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_userdata);
	$sth->execute($pattern, $pattern, $pattern)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_userdata,
			"[uid LIKE $pattern, firstname LIKE $pattern, surname LIKE $pattern]");


	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		next if $$row{uid} =~ /\$$/;

		$re{$$row{uid}} = $row;
	}


	return \%re;
}




=head3 C<find_classes($query)>

Returns classes

=head4 Parameters

=over

=item C<$query>

A query to match classes

=back

=head4 Return value

A reference to a hash with UIDs as key and userdata as value

=head4 Description

Returns the classes on which the pattern of query matches.

=cut

sub find_classes {
	my $query = shift;

	$query =~ tr/*/%/;
	my $pattern = "\%\L$query\E\%";

	my $prepare_classdata = 'SELECT * FROM classdata '
		. 'WHERE     type = \'adminclass\''
		. '      AND (gid LIKE ? OR LOWER(displayname) LIKE ?)';
	my $sth = $_dbh->prepare($prepare_classdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_classdata);
	$sth->execute($pattern, $pattern)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_classdata,
			"[gid LIKE $pattern, displayname LIKE $pattern]");


	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{gid}} = $row;
	}


	return \%re;
}




=head3 C<find_projects($query)>

Returns projects

=head4 Parameters

=over

=item C<$query>

A query to match projects

=back

=head4 Return value

A reference to a hash with UIDs as key and userdata as value

=head4 Description

Returns the projects on which the pattern of query matches.

=cut

sub find_projects {
	my $query = shift;

	$query =~ tr/*/%/;
	my $pattern = "\%\L$query\E\%";

	my $prepare_projectdata = 'SELECT * FROM projectdata '
		. 'WHERE   gid LIKE ?'
		    . ' OR LOWER(displayname) LIKE ?'
		    . ' OR LOWER(longname) LIKE ?';
	my $sth = $_dbh->prepare($prepare_projectdata)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_PREPARE_FAILED,
			$prepare_projectdata);
	$sth->execute($pattern, $pattern, $pattern)
		or die new Schulkonsole::Error(Schulkonsole::Error::DB_EXECUTE_FAILED,
			$prepare_projectdata,
			"[gid LIKE $pattern, displayname LIKE $pattern, longname LIKE $pattern]");


	my %re;
	while (my $row = $sth->fetchrow_hashref) {
		$re{$$row{gid}} = $row;
	}


	return \%re;
}





=head3 C<reconnect()>

Reconnect to DB

=cut

sub reconnect {
	undef $_dbh;
	db_connect();
}




sub db_connect {
	if (not defined $_dbh) {
		my %conf = Schulkonsole::Config::db();

		$_dbh = DBI->connect($conf{DSN}, $conf{Username}, $conf{Password})
			or die DBI->errstr;
		$_dbh->{FetchHashKeyName} = 'NAME_lc';
	}

	return $_dbh;
}





BEGIN {
	db_connect();
}





1;
