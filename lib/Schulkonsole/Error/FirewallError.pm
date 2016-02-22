use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::FirewallError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_INVALID_HOST
	WRAPPER_NO_HOSTS
	WRAPPER_INVALID_ROOM
	WRAPPER_INVALID_LESSONMODE
	WRAPPER_INVALID_LESSONTIME
	WRAPPER_CANNOT_WRITE_ROOMFILE
	WRAPPER_CANNOT_READ_ROOMFILE
);

# package constants
use constant {
	WRAPPER_INVALID_HOST => Schulkonsole::Error::Error::NEXT_ERROR - 1,
	WRAPPER_NO_HOSTS => Schulkonsole::Error::Error::NEXT_ERROR - 2,
	WRAPPER_INVALID_ROOM => Schulkonsole::Error::Error::NEXT_ERROR - 3,
	WRAPPER_INVALID_LESSONMODE => Schulkonsole::Error::Error::NEXT_ERROR - 4,
	WRAPPER_INVALID_LESSONTIME => Schulkonsole::Error::Error::NEXT_ERROR - 5,
	WRAPPER_CANNOT_WRITE_ROOMFILE => Schulkonsole::Error::Error::NEXT_ERROR - 6,
	WRAPPER_CANNOT_READ_ROOMFILE => Schulkonsole::Error::Error::NEXT_ERROR - 7,
	WRAPPER_INVALID_ROOM_SCOPE => Schulkonsole::Error::Error::NEXT_ERROR - 8,
	WRAPPER_CANNOT_OPEN_PRINTERSCONF => Schulkonsole::Error::Error::NEXT_ERROR - 9,
};

sub new {
	my $class = shift;
	my $this = $class->SUPER::new(@_);
	bless $this, $class;
	
	return $this;
}

sub what {
	my $this = shift;
	SWITCH: {
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_HOST
		and return $this->{d}->get('Ungültiger Host');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_NO_HOSTS
		and return $this->{d}->get('Keine Hosts');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_ROOM
		and return $this->{d}->get('Ungültige Raumbezeichnung');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_LESSONMODE
		and return $this->{d}->get('Ungültiger Modus für Unterricht');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_LESSONTIME
		and return $this->{d}->get('Ungültige Zeitangabe für Unterrichtsende');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_WRITE_ROOMFILE
		and return $this->{d}->get('Raumdatei kann nicht geschrieben werden');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_READ_ROOMFILE
		and return $this->{d}->get('Raumdatei kann nicht gelesen werden');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_ROOM_SCOPE
		and return $this->{d}->get('Erwarte 0 oder 1 für scope');
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_OPEN_PRINTERSCONF
	        and return $this->{d}->get('Kann printers.conf nicht öffnen');
	};
	return $this->SUPER::what();
}



1;
