use strict;
use utf8;
use POSIX;
eval {
	require Locale::gettext;
	Locale::gettext->require_version(1.04);
};
if ($@) {
	require Schulkonsole::Gettext;
}

package Schulkonsole::Error::Error;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	new
	what
	errstr
	fetch_error_string

	OK
	PERL_ERROR
	PUBLIC_BG_ERROR
	DB_PREPARE_FAILED
	DB_EXECUTE_FAILED
	DB_FETCH_FAILED
	INTERNAL_BG_ERROR
	UNKNOWN_PASSWORD_ENCRYPTION
	DB_USER_DOES_NOT_EXIST
	DB_NO_WORKSTATION_USERS
	CANNOT_OPEN_FILE
	FILE_FORMAT_ERROR
	WRAPPER_GENERAL_ERROR
	WRAPPER_EXEC_FAILED
	WRAPPER_BROKEN_PIPE_OUT
	WRAPPER_BROKEN_PIPE_IN
	WRAPPER_WRONG
	WRAPPER_UNKNOWN
	WRAPPER_PROGRAM_ERROR
	WRAPPER_UNAUTHORIZED_UID
	WRAPPER_INVALID_UID
	WRAPPER_SETUID_FAILED
	WRAPPER_INVALID_SCRIPT
	WRAPPER_SCRIPT_EXEC_FAILED
	WRAPPER_UNAUTHENTICATED_ID
	WRAPPER_APP_ID_DOES_NOT_EXIST
	WRAPPER_UNAUTHORIZED_ID
	WRAPPER_INVALID_SESSION_ID
	WRAPPER_CANNOT_FORK
	WRAPPER_CANNOT_OPEN_FILE
	USER_AUTHENTICATION_FAILED
	UNKNOWN_GROUP
	NEXT_ERROR
);

# package constants
use constant {
	OK => 0,
	PERL_ERROR  => -1,
	PUBLIC_BG_ERROR => -2,
	INTERNAL => -3,
	DB_PREPARE_FAILED => -4,
	DB_EXECUTE_FAILED => -5,
	DB_FETCH_FAILED => -6,
	INTERNAL_BG_ERROR => -7,
	UNKNOWN_PASSWORD_ENCRYPTION => -8,
	DB_USER_DOES_NOT_EXIST => -9,
	DB_NO_WORKSTATION_USERS => -10,
	CANNOT_OPEN_FILE => -11,
	FILE_FORMAT_ERROR => -12,
	WRAPPER_GENERAL_ERROR => -13,
	WRAPPER_EXEC_FAILED => -14,
	WRAPPER_BROKEN_PIPE_OUT => -15,
	WRAPPER_BROKEN_PIPE_IN => -16,
	WRAPPER_WRONG => -17,
	WRAPPER_UNKNOWN => -18,
	WRAPPER_PROGRAM_ERROR => -19,
	WRAPPER_UNAUTHORIZED_UID => -20,
	WRAPPER_INVALID_UID => -21,
	WRAPPER_SETUID_FAILED => -22,
	WRAPPER_INVALID_SCRIPT => -24,
	WRAPPER_SCRIPT_EXEC_FAILED => -25,
	WRAPPER_UNAUTHENTICATED_ID => -26,
	WRAPPER_APP_ID_DOES_NOT_EXIST => -27,
	WRAPPER_UNAUTHORIZED_ID => -28,
	WRAPPER_INVALID_SESSION_ID => -29,
	WRAPPER_CANNOT_FORK => -30,
	WRAPPER_CANNOT_OPEN_FILE => -31,
	USER_AUTHENTICATION_FAILED => -32,
	UNKNOWN_GROUP => -33,
	NEXT_ERROR => -64,
	
	EXTERNAL_ERROR => 128,
	
};

use overload
	'""' => \&errstr;





sub new {
	my $class = shift;
	my $this = {};
	bless $this, $class;
	$this->_init(@_);
	return $this;
}

sub _init {
	my $this = shift;
	my $code = shift;
	my $info = @_ ? \@_ : undef;

	$$this{code} = $code;
	#FIXME: $$this{internal} = $code >= INTERNAL;
	$$this{info} = $info;
	$$this{d} = Locale::gettext->domain('schulkonsole');
	$this->{d}->dir('/usr/share/locale');
}



sub what {
	my $this = shift;

	SWITCH: {
	$this->{code} == OK and return $this->{d}->get('kein Fehler');
	$this->{code} == PERL_ERROR
		and return $this->{d}->get('Perl Kompilierungsfehler') . ${$this->{info}}[0];
	$this->{code} == PUBLIC_BG_ERROR
		and return $this->{d}->get('Fehler im Hintergrundprozess: ') . ${ $this->{info} }[0];
	$this->{code} == INTERNAL_BG_ERROR
		and return $this->{d}->get('Fehler im Hintergrundprozess');
	$this->{code} == DB_PREPARE_FAILED
		and return $this->{d}->get('Prepare fehlgeschlagen');
	$this->{code} == DB_EXECUTE_FAILED
		and return $this->{d}->get('Execute fehlgeschlagen');
	$this->{code} == DB_FETCH_FAILED
		and return $this->{d}->get('Fetch fehlgeschlagen');
	$this->{code} == UNKNOWN_PASSWORD_ENCRYPTION
		and return $this->{d}->get('Unbekannte Passwortverschluesselung');
	$this->{code} == DB_USER_DOES_NOT_EXIST
		and return $this->{d}->get('Benutzer existiert nicht');
	$this->{code} == DB_NO_WORKSTATION_USERS
		and return $this->{d}->get('Keine Workstationbenutzer');
	$this->{code} == CANNOT_OPEN_FILE
		and return $this->{d}->get('Kann Datei nicht oeffnen');
	$this->{code} == FILE_FORMAT_ERROR
		and return $this->{d}->get('Datei hat falsches Format');
	$this->{code} == WRAPPER_GENERAL_ERROR
		and return $this->{d}->get('Allgemeiner Fehler');
	$this->{code} == WRAPPER_EXEC_FAILED
		and return $this->{d}->get('Wrapperaufruf fehlgeschlagen');
	$this->{code} == WRAPPER_BROKEN_PIPE_OUT
		and return $this->{d}->get('Datenuebertragung (schreiben) unterbrochen');
	$this->{code} == WRAPPER_BROKEN_PIPE_IN
		and return $this->{d}->get('Datenuebertragung (lesen) unterbrochen');
	$this->{code} == WRAPPER_WRONG
		and return $this->{d}->get('Falscher Programmaufruf') . ' [' . join(', ', (caller(2))[1..3]) . ']';
	$this->{code} == WRAPPER_UNKNOWN
		and return $this->{d}->get('Unbekannter Programmaufruf');
	$this->{code} == WRAPPER_PROGRAM_ERROR
		and return $this->{d}->get('Programmaufruf fehlgeschlagen');
	$this->{code} == WRAPPER_UNAUTHORIZED_UID
		and return $this->{d}->get('Nicht autorisierter Aufrufer');
	$this->{code} == WRAPPER_INVALID_UID
		and return $this->{d}->get('Wechsel zu diesem Benutzer nicht erlaubt');
	$this->{code} == WRAPPER_SETUID_FAILED
		and return $this->{d}->get('Wechsel zu diesem Benutzer nicht moeglich');
	$this->{code} == WRAPPER_INVALID_SCRIPT
		and return $this->{d}->get('Skript nicht vorhanden');
	$this->{code} == WRAPPER_SCRIPT_EXEC_FAILED
		and return $this->{d}->get('Skriptaufruf fehlgeschlagen');
	$this->{code} == WRAPPER_UNAUTHENTICATED_ID
		and return $this->{d}->get('Authentifizierung fehlgeschlagen nach ID');
	$this->{code} == WRAPPER_APP_ID_DOES_NOT_EXIST
		and return $this->{d}->get('Programm-ID unbekannt');
	$this->{code} == WRAPPER_UNAUTHORIZED_ID
		and return $this->{d}->get('Nicht autorisierter Aufrufer nach ID');
	$this->{code} == WRAPPER_INVALID_SESSION_ID
		and return $this->{d}->get('Ungueltige Session-ID');
	$this->{code} == WRAPPER_CANNOT_FORK
		and return $this->{d}->get('Fork nicht moeglich');
	$this->{code} == WRAPPER_CANNOT_OPEN_FILE
		and return $this->{d}->get('Kann Datei nicht oeffnen');
	$this->{code} == USER_AUTHENTICATION_FAILED
		and return $this->{d}->get('Authentifizierung fehlgeschlagen');
	$this->{code} == UNKNOWN_GROUP
		and return $this->{d}->get('Unbekannte Gruppe');
	int($this->{code} / EXTERNAL_ERROR) * EXTERNAL_ERROR == EXTERNAL_ERROR
		and return $this->fetch_error_string($this->{code} % EXTERNAL_ERROR);
	$this->{what}
		and return $this->{what};

	return $this->{d}->get('Unbekannter Fehler ') . $this->{code}
		. ' [' . join(', ', (caller(2))[1..3]) . ']'; 
	}
}

sub fetch_error_string {
	my $this = shift;
	my $extcode = shift;
	return $this->{d}->get('Unbekannter externer Fehler ') . $this->{extcode}
		. ' [' . join(', ', (caller(2))[1..3]) . ']';
}

sub errstr {
	my $this = shift;

	return $0
		. ': '
		. $this->what()
		. ($this->{info} ? ' (' . join(', ', @{ $this->{info} }) . ')' : '')
		. "\n";
}





1;
