use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::HordeError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_SETUID_FAILED
	WRAPPER_INVALID_ADDRESSES
	WRAPPER_NO_ADDRESSES
);

# package constants
use constant {
	WRAPPER_SETUID_FAILED => Schulkonsole::Error::Error::NEXT_ERROR -1,
	WRAPPER_INVALID_ADDRESSES => Schulkonsole::Error::Error::NEXT_ERROR -2,
	WRAPPER_NO_ADDRESSES => Schulkonsole::Error::Error::NEXT_ERROR -3,
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
	$this->{code} == WRAPPER_SETUID_FAILED
		and return $this->{d}->get('Wechsel zu diesem Benutzer nicht möglich');
	$this->{code} == WRAPPER_INVALID_ADDRESSES
		and return $this->{d}->get('Ungültige E-Mail-Adressen angegeben');
	$this->{code} == WRAPPER_NO_ADDRESSES
		and return $this->{d}->get('Keine E-Mail-Adressen angegeben');
	};
	return $this->SUPER::what();
}


1;
