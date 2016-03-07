use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::CyrusError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_NO_CYRUS_USER
	WRAPPER_INVALID_EUID
);

# package constants
use constant {
	WRAPPER_NO_CYRUS_USER => Schulkonsole::Error::Error::NEXT_ERROR - 1,
	WRAPPER_INVALID_EUID  => Schulkonsole::Error::Error::NEXT_ERROR - 1,
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
	$this->{code} == WRAPPER_NO_CYRUS_USER
		and return $this->{d}->get('Benutzer "cyrus" gibt es nicht');
	$this->{code} == WRAPPER_INVALID_EUID
		and return $this->{d}->get('wrapper-cyrus gehoert nicht Benutzer "cyrus" oder SUID nicht gesetzt');
	};
	return $this->SUPER::what();
}



1;
