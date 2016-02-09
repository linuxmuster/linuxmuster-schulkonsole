use strict;
use base("Error");

package Schulkonsole::Error::ExternalError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Schulkonsole::Error::Error Exporter);
@EXPORT_OK = qw(
	new
	what
	errstr
);


use overload
	'""' => \&errstr;





sub new {
	my $class = shift;
	my $errstr = shift;
	my $internal = shift;
	my $info = @_ ? \@_ : undef;

	my $this = {
		code => 0,
		errstr => $errstr,
		internal => $internal,
		info => $info,
	};

	bless $this, $class;

	return $this;
}




sub what {
	my $this = shift;

	return ($this->{errstr} ?  $this->{errstr} : 'Unbekannter Fehler');
}



sub errstr {
	my $this = shift;

	return $0
		. ': '
		. ($this->{errstr} ?
		     $this->{errstr}
		   : 'Unbekannter Fehler [' . join(', ', (caller(2))[1..3]) . ']')
		. "\n"
		. ($this->{info} ? ' (' . join(', ', @{ $this->{info} }) . ')' : '')
		. "\n";
}





1;
