use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::FilesError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	WRAPPER_INVALID_FILENUMBER
	WRAPPER_CANNOT_OPEN_FILE
	WRAPPER_INVALID_SESSION_ID
);

# package constants
use constant {
	WRAPPER_INVALID_FILENUMBER => Schulkonsole::Error::Error::NEXT_ERROR - 1,
	WRAPPER_CANNOT_OPEN_FILE   => Schulkonsole::Error::Error::NEXT_ERROR - 2,
	WRAPPER_INVALID_SESSION_ID => Schulkonsole::Error::Error::NEXT_ERROR - 3,
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
	$this->{code} == WRAPPER_INVALID_FILENUMBER
		and return $this->{d}->get('Ungültiger Wert für number');
	 $this->{code} == WRAPPER_CANNOT_OPEN_FILE
		and return $this->{d}->get('Kann Datei nicht öffnen');
	$this->{code} == WRAPPER_INVALID_SESSION_ID
		and return $this->{d}->get('Ungültige Session-ID');
	};
	return $this->SUPER::what();
}



1;
