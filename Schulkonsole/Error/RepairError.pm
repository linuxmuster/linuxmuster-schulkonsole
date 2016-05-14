use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::RepairError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_NO_CLASS
	WRAPPER_NO_PROJECT
	WRAPPER_PROCESS_RUNNING
	WRAPPER_CANNOT_DELETE_LOG
	WRAPPER_NO_GROUP
	WRAPPER_INVALID_GROUP
	WRAPPER_INVALID_COMMAND
	WRAPPER_NO_USER
);

# package constants
use constant {
#  <<Hier mit absteigenden Nummern die Fehlernummern zu den Fehlern hinzufügen: >>
	WRAPPER_NO_CLASS => Schulkonsole::Error::Error::NEXT_ERROR - 1,
	WRAPPER_NO_PROJECT => Schulkonsole::Error::Error::NEXT_ERROR - 2,
	WRAPPER_PROCESS_RUNNING => Schulkonsole::Error::Error::NEXT_ERROR - 3,
	WRAPPER_CANNOT_DELETE_LOG => Schulkonsole::Error::Error::NEXT_ERROR - 4,
	WRAPPER_NO_GROUP => Schulkonsole::Error::Error::NEXT_ERROR - 5,
	WRAPPER_INVALID_GROUP => Schulkonsole::Error::Error::NEXT_ERROR - 6,
	WRAPPER_INVALID_COMMAND => Schulkonsole::Error::Error::NEXT_ERROR - 7,
	WRAPPER_NO_USER => Schulkonsole::Error::Error::NEXT_ERROR - 8,
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
	$this->{code} == WRAPPER_NO_CLASS
		and return $this->{d}->get('Es wurde keine Klasse angegeben.');
	$this->{code} == WRAPPER_NO_PROJECT
		and return $this->{d}->get('Es wurde kein Projekt angegeben.');
	$this->{code} == WRAPPER_PROCESS_RUNNING
		and return $this->{d}->get('Es läuft bereits eine Reparatur.');
	$this->{code} == WRAPPER_CANNOT_DELETE_LOG
		and return $this->{d}->get('Die Log-Datei kann nicht zurückgesetzt werden.');
	$this->{code} == WRAPPER_NO_GROUP
		and return $this->{d}->get('Es wurde keine Gruppe angegeben.');
	$this->{code} == WRAPPER_INVALID_GROUP
		and return $this->{d}->get('Die angegebene Gruppe existiert nicht.');
	$this->{code} == WRAPPER_INVALID_COMMAND
		and return $this->{d}->get('Die angegebene Befehlsnummer existiert nicht.');
	$this->{code} == WRAPPER_NO_USER
		and return $this->{d}->get('Es wurde kein Benutzer angegeben.');
	};
	return $this->SUPER::what();
}



1;
