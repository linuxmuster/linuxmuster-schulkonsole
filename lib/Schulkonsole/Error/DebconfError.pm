use strict;
use utf8;
use parent("Schulkonsole::Error::Error");

package Schulkonsole::Error::Debconf;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_INVALID_SECTION
	WRAPPER_INVALID_NAME
	WRAPPER_INVALID_REQUEST
);

# package constants
use constant {
	WRAPPER_INVALID_SECTION => Schulkonsole::Error::Error::NEXT_ERROR -1,
	WRAPPER_INVALID_NAME    => Schulkonsole::Error::Error::NEXT_ERROR -2,
	WRAPPER_INVALID_REQUEST => Schulkonsole::Error::Error::NEXT_ERROR -3,
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
	$this->{code} == WRAPPER_INVALID_SECTION
		and return $this->{d}->get('Ungültiger Debconf-Bereich');
	$this->{code} == WRAPPER_INVALID_NAME
		and return $this->{d}->get('Ungültiger Debconf-Name');
	$this->{code} == WRAPPER_INVALID_REQUEST
		and return $this->{d}->get('Dieser Bereich/Name darf nicht abgefragt werden');
	};
	return $this->SUPER::what();
}


1;
