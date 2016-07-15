use strict;
use utf8;
use parent("Schulkonsole::Error::Error");

package Schulkonsole::Error::UserError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	
	WRAPPER_SETUID_FAILED
);

# package constants
use constant {
	WRAPPER_SETUID_FAILED => Schulkonsole::Error::Error::NEXT_ERROR - 1,
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
	};
	return $this->SUPER::what();
}


1;
