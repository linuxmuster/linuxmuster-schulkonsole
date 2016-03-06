use strict;
use IPC::Open3;
use POSIX 'sys_wait_h';
use Schulkonsole::Wrapper;
use Schulkonsole::Error::Error;
use Schulkonsole::Error::MusterError;
use Schulkonsole::Config;


package Schulkonsole::Muster;

=head1 NAME

Schulkonsole::Muster - Muster einer Schulkonsolenbibliothek

=head1 SYNOPSIS

 use Schulkonsole::Muster;

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

my $wrapcmd = '/usr/lib/schulkonsole/bin/wrapper-muster';
my $errorclass = "Schulkonsole::Error::MusterError";

=head2 Functions

=head3 C<funktion1($id, $password, <<weitere Parameter>>)>

<<Beschreibung der Funktion in einem Satz>>

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

<<Beschreibung des Funktionsaufrufs>>

=cut

sub funktion1 {
	my $id = shift;
	my $password = shift;
=item
    <<Befehl ohne Rückgabe, Befehlsnumer 1 im Wrapper>>
=cut

	Schulkonsole::Wrapper::wrapcommand($wrapcmd, $errorclass, 1,$id, $password);
}




=head3 C<funktion2($id, $password)>

 <<>>

=head3 Parameters

=over

=item C<$id>

The ID (not UID) of the user invoking the command

=item C<$password>

The password of the user invoking the command

=back

=head3 Description

<<>>

=cut

sub funktion2 {
	my $id = shift;
	my $password = shift;
=item
 <<Befehl mit Rückgabe, Befehlsnummer 2 im Wrapper>>
=cut

	my $in = Schulkonsole::Wrapper::wrap($wrapcmd, $errorclass, 2, $id, $password);
	
	return $in;
}

=item
 <<weitere Befehle>>
=cut

1;
