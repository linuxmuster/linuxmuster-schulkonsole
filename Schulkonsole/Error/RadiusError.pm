use strict;
use utf8;
use parent("Schulkonsole::Error::Error");

package Schulkonsole::Error::RadiusError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_INVALID_GROUP
	WRAPPER_NO_GROUPS
	WRAPPER_INVALID_LESSONMODE
	WRAPPER_INVALID_LESSONTIME
	WRAPPER_CANNOT_WRITE_GROUPFILE
	WRAPPER_CANNOT_READ_GROUPFILE
);

# package constants
use constant {
	WRAPPER_INVALID_GROUP          => Schulkonsole::Error::Error::NEXT_ERROR -1,
	WRAPPER_NO_GROUPS              => Schulkonsole::Error::Error::NEXT_ERROR -2,
	WRAPPER_INVALID_LESSONMODE     => Schulkonsole::Error::Error::NEXT_ERROR -3,
	WRAPPER_INVALID_LESSONTIME     => Schulkonsole::Error::Error::NEXT_ERROR -4,
	WRAPPER_CANNOT_WRITE_GROUPFILE => Schulkonsole::Error::Error::NEXT_ERROR -5,
	WRAPPER_CANNOT_READ_GROUPFILE  => Schulkonsole::Error::Error::NEXT_ERROR -6,
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
		$this->{code} == WRAPPER_INVALID_GROUP
			and return $this->{d}->get('Ungültige Gruppe');
		$this->{code} == WRAPPER_NO_GROUPS
			and return $this->{d}->get('Keine Gruppen angegeben');
		$this->{code} == WRAPPER_INVALID_LESSONMODE
			and return $this->{d}->get('Ungültiger Modus für Unterricht');
		$this->{code} == WRAPPER_INVALID_LESSONTIME
			and return $this->{d}->get('Ungültige Unterrichtszeit');
		$this->{code} == WRAPPER_CANNOT_WRITE_GROUPFILE
			and return $this->{d}->get('Gruppendatei konnte nicht geschrieben werden');
		$this->{code} == WRAPPER_CANNOT_READ_GROUPFILE
			and return $this->{d}->get('Gruppendatei konnte nicht gelesen werden');
	};
	return $this->SUPER::what();
}


1;
