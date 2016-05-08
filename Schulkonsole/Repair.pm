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

 <<Hier sollten die exportieren Funktionen erläutert werden.>>
 
=head1 DESCRIPTION

 <<Hier sollte das Modul beschrieben werden.>>
 
=cut

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
 <<Hier müssen die exportierten Funktionen auftelistet werden.>>
 funktion1
);


=head2 Functions

<<Falls Befehle mit root-Rechten benötigt werden:>>

=cut

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

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, Schulkonsole::Config::REPAIRPERMISSIONSAPP,$id, $password, @_);
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


1;
