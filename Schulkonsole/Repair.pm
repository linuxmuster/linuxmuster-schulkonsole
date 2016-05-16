use CGI::Inspect;
use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::RepairError;
use Schulkonsole::Config;


package Schulkonsole::Repair;

=head1 NAME

Schulkonsole::Repair - Schulkonsolenbibliothek zum Reparieren von Verzeichnissen / Rechten

=head1 SYNOPSIS

 use Schulkonsole::Repair;

 repair_homes($id,$password,STUDENTS);
 
 Die Befehle in diesem Modul bieten einen Zugriff auf den Befehl
 
 sophomorix-repair
 
 (siehe auch man sophomorix-repair).
 
 
=head1 DESCRIPTION

  Das Modul ermöglicht den Aufruf von sophomorix-repair zum Reparieren von
  Verzeichnissen und Verzeichnisrechten.
  
=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    repair_permissions
    repair_myhome
    repair_classhomes
    repair_projecthomes
    repair_homes
    read_repair_log_file
    repair_get_info
    
    LOGFILE
    STUDENTS
    TEACHERS
    WORKSTATIONS
    ALL
);

=head2 Konstanten

=item C<STUDENTS>

Select all students homes for repair

=item C<TEACHERS>

Select all teachers homes for repair

=item C<WORKSTATIONS>

Select all workstations home for repair

=item C<ALL>

Select all users homes for repair

=cut

use constant {
  STUDENTS => 1,
  TEACHERS => 2,
  WORKSTATIONS => 4,
  ALL => 7,
  LOGFILE => '/var/tmp/sophomorix-repair.log'
};

my $wrapcmd = '/usr/lib/schulkonsole/bin/wrapper-repair';
my $errorclass = "Schulkonsole::Error::RepairError";

=head2 Functions

=head3 C<repair_permissions($id, $password, $nr1, $nr2, ..., $nrn)>

do call sophomorix-repair --permissions --comand-number with given command numbers

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$nr1, $nr2, ..., $nrn>

The command numbers starting 1, ... corresponding to the numbers given by
the command sophomorix-repair --permissions --info

=back

=head3 Description

execute permission repairs by wrapping sophomorix-repair --permissions

=cut

sub repair_permissions {
	my $id = shift;
	my $password = shift;

	my $num = repair_get_info($id, $password);
	if( scalar @$num == scalar @_ ){
		Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRPERMISSIONSAPP,$id, $password,'');
	}
	else {
		Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRPERMISSIONSAPP,$id, $password, join(',', @_));
	}
}


=head3 C<repair_myhome($id, $password)>

do call sophomorix-repair --repairhome -u $uid

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

do repair invoking users home permissions

=cut

sub repair_myhome {
	my $id = shift;
	my $password = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRMYHOMEAPP,$id, $password);
}


=head3 C<repair_classhomes($id, $password, $class)>

do call sophomorix-repair --repairhome -c $class

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$class>

The class which students' homes will be repaired

=back

=head3 Description

do repair class students' home folders

=cut

sub repair_classhomes {
	my $id = shift;
	my $password = shift;
	my $class = shift;

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRCLASSHOMESAPP,$id, $password, $class);
}


=head3 C<repair_projecthomes($id, $password, $project)>

do call sophomorix-repair --repairhome -p $project

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$project>

The project members homes will be repaired

=back

=head3 Description

do repair project members home folders

=cut

sub repair_projecthomes {
	my $id = shift;
	my $password = shift;
	my $project = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRPROJECTHOMESAPP,$id, $password, $project);
}


=head3 C<repair_homes($id, $password, $usergroup)>

do call sophomorix-repair --repairhome with specified usergroup

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=item C<$usergroup>

Select $usergroup (either STUDENTS, TEACHERS, WORKSTATIONS or ALL)

=back

=head3 Description

do repair selected users homes

=cut

sub repair_homes {
	my $id = shift;
	my $password = shift;
	my $usergroup = shift;
	
	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRHOMESAPP,$id, $password, $usergroup);
}


=head3 C<repair_get_info($id, $password)>

do call sophomorix-repair --permissions --info
to get a numbered command list.

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Return Value

Returns the commands as array reference.


=head3 Description

return output displaying the lines of sophomorix-repair --permissions --info

=cut

sub repair_get_info {
	my $id = shift;
	my $password = shift;
	
	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRGETINFOAPP,$id, $password);
	
	my @directories;
	foreach my $line (split('\n', $in)) {
	  next unless $line =~ /Nr\./;
	  my ($nr, $dir, $user, $group, $rights) = $line =~ /^Nr\.\s*(\d+):\s*(\S+?)::(\w+?)::(\w+?)::(\d+?)$/;
	  next unless $nr and $dir and $user and $group and $rights;
	  my %dir = (nr => $nr, dir => $dir, user => $user, group => $group, permissions => $rights, repair => 0,
		    );
	  push @directories, \%dir;
	}


	return \@directories;
}

=head3 C<read_repair_log_file($id, $password)>

Read sophomorix-repair log file, if existing

=head4 Parameters

=over

=item C<$id>

The ID (not UID) of the admin invoking the command

=item C<$password>

The password of the admin invoking the command

=back

=head4 Return value

A reference to an array of the lines in the log file

=head4 Description

Reads the sorted list of
/var/tmp/sophomorix-repair.log if existing.

=cut

sub read_repair_log_file {
        my @re;
	if (not -e Schulkonsole::Encode::to_fs(LOGFILE)){
		sleep 1;
	}
        if (open REPAIRLOG, '<', Schulkonsole::Encode::to_fs(LOGFILE)) {
            while (<REPAIRLOG>) {
                    push @re, $_;
            }
            close REPAIRLOG;
        } else {
                warn "$0: Cannot open "
                    . LOGFILE
                    . ": $!\n";
        }
        
        return \@re;
}


1;
