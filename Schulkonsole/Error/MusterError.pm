use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::MusterError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
 <<Hier eigene Fehlersymbole hinzufügen>>
 MEIN_ERSTER_FEHLER
);

# package constants
use constant {
#  <<Hier mit absteigenden Nummern die Fehlernummern zu den Fehlern hinzufügen: >>
	MEIN_ERSTER_FEHLER => Schulkonsole::Error::Error::NEXT_ERROR - 1,
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
		<<Hier die Fehlermeldungen zu den Fehlern hinzufügen>>
	$this->{code} == MEIN_ERSTER_FEHLER
		and return $this->{d}->get('Mein erster Fehler ist aufgetreten');
	};
	return $this->SUPER::what();
}



1;
