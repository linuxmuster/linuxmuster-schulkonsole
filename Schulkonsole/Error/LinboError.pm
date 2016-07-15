use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::LinboError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	START_CONF_ERROR
	WRAPPER_INVALID_GROUP
	WRAPPER_INVALID_FILENAME
	WRAPPER_INVALID_IS_EXAMPLE
	WRAPPER_INVALID_IMAGE
	WRAPPER_INVALID_ACTION
	WRAPPER_CANNOT_OPEN_FILE
	WRAPPER_CANNOT_RUN_COMMAND
	WRAPPER_INVALID_TYPE
	WRAPPER_INVALID_TARGET
	WRAPPER_NO_SUCH_HOST
	WRAPPER_NO_SUCH_GROUP
	WRAPPER_NO_SUCH_ROOM
	WRAPPER_INVALID_RUN
	WRAPPER_INVALID_COMMANDS
	WRAPPER_INVALID_ARG
	WRAPPER_INVALID_SESSION_NAME
	WRAPPER_CANNOT_OPEN_LINBOCMD
	WRAPPER_CANNOT_CLOSE_LINBOCMD
	WRAPPER_INVALID_IP
	INVALID_GROUP
);

# package constants
use constant {
	START_CONF_ERROR => 50,
	WRAPPER_INVALID_GROUP        => Schulkonsole::Error::Error::NEXT_ERROR -1,
	WRAPPER_INVALID_FILENAME     => Schulkonsole::Error::Error::NEXT_ERROR -2,
	WRAPPER_INVALID_IS_EXAMPLE   => Schulkonsole::Error::Error::NEXT_ERROR -3,
	WRAPPER_INVALID_IMAGE        => Schulkonsole::Error::Error::NEXT_ERROR -4,
	WRAPPER_INVALID_ACTION       => Schulkonsole::Error::Error::NEXT_ERROR -5,
	WRAPPER_CANNOT_OPEN_FILE     => Schulkonsole::Error::Error::NEXT_ERROR -6,
	WRAPPER_CANNOT_RUN_COMMAND   => Schulkonsole::Error::Error::NEXT_ERROR -7,
	WRAPPER_INVALID_TYPE         => Schulkonsole::Error::Error::NEXT_ERROR -8,
	WRAPPER_INVALID_TARGET       => Schulkonsole::Error::Error::NEXT_ERROR -9,
	WRAPPER_NO_SUCH_HOST         => Schulkonsole::Error::Error::NEXT_ERROR -10,
	WRAPPER_NO_SUCH_GROUP        => Schulkonsole::Error::Error::NEXT_ERROR -11,
	WRAPPER_NO_SUCH_ROOM         => Schulkonsole::Error::Error::NEXT_ERROR -12,
	WRAPPER_INVALID_RUN          => Schulkonsole::Error::Error::NEXT_ERROR -13,
	WRAPPER_INVALID_COMMANDS     => Schulkonsole::Error::Error::NEXT_ERROR -14,
	WRAPPER_INVALID_ARG          => Schulkonsole::Error::Error::NEXT_ERROR -15,
	WRAPPER_INVALID_SESSION_NAME => Schulkonsole::Error::Error::NEXT_ERROR -16,
	WRAPPER_CANNOT_OPEN_LINBOCMD => Schulkonsole::Error::Error::NEXT_ERROR -17,
	WRAPPER_CANNOT_CLOSE_LINBOCMD => Schulkonsole::Error::Error::NEXT_ERROR -18,
	WRAPPER_INVALID_IP           => Schulkonsole::Error::Error::NEXT_ERROR -19,
	INVALID_GROUP                => Schulkonsole::Error::Error::NEXT_ERROR - 20,
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
	$this->{code} == START_CONF_ERROR
		and return $this->{d}->get('Fehler in der Konfiguration');
	$this->{code} == WRAPPER_INVALID_GROUP
		and return $this->{d}->get('Ungültiger Gruppenname');
	$this->{code} == WRAPPER_INVALID_FILENAME
		and return $this->{d}->get('Ungültiger Dateiname');
	$this->{code} == WRAPPER_INVALID_IS_EXAMPLE
		and return $this->{d}->get('Erwarte 1 oder 0 für is_example');
	$this->{code} == WRAPPER_INVALID_IMAGE
		and return $this->{d}->get('Ungültiger Image-Dateiname');
	$this->{code} == WRAPPER_INVALID_ACTION
		and return $this->{d}->get('action muss 0, 1 oder 2 sein');
	$this->{code} == WRAPPER_CANNOT_RUN_COMMAND
		and return $this->{d}->get('Befehl konnte nicht ausgeführt werden');
	$this->{code} == WRAPPER_INVALID_TYPE
		and return $this->{d}->get('Ungültiger Typ');
	$this->{code} == WRAPPER_INVALID_TARGET
		and return $this->{d}->get('Ungültiges Ziel');
	$this->{code} == WRAPPER_NO_SUCH_HOST
		and return $this->{d}->get('Rechner nicht gefunden');
	$this->{code} == WRAPPER_NO_SUCH_GROUP
		and return $this->{d}->get('Gruppe nicht gefunden');
	$this->{code} == WRAPPER_NO_SUCH_ROOM
		and return $this->{d}->get('Raum nicht gefunden');
	$this->{code} == WRAPPER_INVALID_RUN
		and return $this->{d}->get('Ungültiger Programmablauf');
	$this->{code} == WRAPPER_INVALID_COMMANDS
		and return $this->{d}->get('Ungültige Befehle');
	$this->{code} == WRAPPER_INVALID_ARG
		and return $this->{d}->get('Ungültiges Argument');
	$this->{code} == WRAPPER_INVALID_SESSION_NAME
		and return $this->{d}->get('Ungültiger Session-Name');
	$this->{code} == WRAPPER_CANNOT_OPEN_LINBOCMD
		and return $this->{d}->get('Kann linbocmd Datei nicht öffnen');
	$this->{code} == WRAPPER_CANNOT_CLOSE_LINBOCMD
		and return $this->{d}->get('Kann linbocmd Datei nicht schließen');
	$this->{code} == WRAPPER_INVALID_IP
		and return $this->{d}->get('Ungültige IP');
	$this->{code} == INVALID_GROUP
		and return $this->{d}->get('Ungültige Gruppe');
	};
	return $this->SUPER::what();
}


1;
