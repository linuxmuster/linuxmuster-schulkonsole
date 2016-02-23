use strict;
use utf8;
use parent("Schulkonsole::Error::Error");

package Schulkonsole::Error::PrinterError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_CANNOT_OPEN_PRINTERSCONF
	WRAPPER_INVALID_PRINTER_NAME
	WRAPPER_NO_PRINTERS
	WRAPPER_INVALID_USER
	WRAPPER_NO_USERS
	WRAPPER_INVALID_PAGES
	WRAPPER_INVALID_MAX_PAGES
	WRAPPER_UNEXPECTED_DATA
);

# package constants
use constant {
	WRAPPER_CANNOT_OPEN_PRINTERSCONF => Schulkonsole::Error::Error::NEXT_ERROR -1,
	WRAPPER_INVALID_PRINTER_NAME     => Schulkonsole::Error::Error::NEXT_ERROR -2,
	WRAPPER_NO_PRINTERS              => Schulkonsole::Error::Error::NEXT_ERROR -3,
	WRAPPER_INVALID_USER             => Schulkonsole::Error::Error::NEXT_ERROR -4,
	WRAPPER_NO_USERS                 => Schulkonsole::Error::Error::NEXT_ERROR -5,
	WRAPPER_INVALID_PAGES            => Schulkonsole::Error::Error::NEXT_ERROR -6,
	WRAPPER_INVALID_MAX_PAGES        => Schulkonsole::Error::Error::NEXT_ERROR -7,
	WRAPPER_UNEXPECTED_DATA          => Schulkonsole::Error::Error::NEXT_ERROR -8,
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
	$this->{code} == WRAPPER_CANNOT_OPEN_PRINTERSCONF
	        and return $this->{d}->get('Kann printers.conf nicht öffnen');
	$this->{code} == WRAPPER_INVALID_PRINTER_NAME
		and return $this->{d}->get('Ungültiger Druckername');
	$this->{code} == WRAPPER_NO_PRINTERS
		and return $this->{d}->get('Keine Drucker');
	$this->{code} == WRAPPER_INVALID_USER
		and return $this->{d}->get('Ungültiger Druckernutzer');
	$this->{code} == WRAPPER_NO_USERS
		and return $this->{d}->get('Keine Benutzer');
	$this->{code} == WRAPPER_INVALID_PAGES
		and return $this->{d}->get('Ungültige Daten für genutzte Druckquota');
	$this->{code} == WRAPPER_INVALID_MAX_PAGES
		and return $this->{d}->get('Ungültige Daten fuer Druckquota');
	$this->{code} == WRAPPER_UNEXPECTED_DATA
		and return $this->{d}->get('Unerwartete Programmausgabe');
	};
	return $this->SUPER::what();
}


1;
