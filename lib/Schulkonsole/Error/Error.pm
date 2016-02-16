use strict;
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
	USER_AUTHENTICATION_FAILED
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
	NEXT_ERROR
);

# package constants
use constant {
	OK => 0,

	USER_AUTHENTICATION_FAILED  => 1,

	PUBLIC_BG_ERROR => 20,

	INTERNAL => 1000,
	DB_PREPARE_FAILED => 1001,
	DB_EXECUTE_FAILED => 1002,
	DB_FETCH_FAILED => 1003,

	INTERNAL_BG_ERROR => 1020,

	UNKNOWN_PASSWORD_ENCRYPTION => 2001,
	DB_USER_DOES_NOT_EXIST => 2002,
	DB_NO_WORKSTATION_USERS => 2003,

	CANNOT_OPEN_FILE => 2501,
	FILE_FORMAT_ERROR => 2502,

	WRAPPER_GENERAL_ERROR => 3001,
	WRAPPER_EXEC_FAILED => 3002,
	WRAPPER_BROKEN_PIPE_OUT => 3003,
	WRAPPER_BROKEN_PIPE_IN => 3004,
	WRAPPER_WRONG => 3005,
	WRAPPER_UNKNOWN => 3006,

	WRAPPER_PROGRAM_ERROR => 3010,
	WRAPPER_UNAUTHORIZED_UID => 3011,
	WRAPPER_INVALID_UID => 3012,
	WRAPPER_SETUID_FAILED => 3013,
	WRAPPER_INVALID_SCRIPT => 3014,
	WRAPPER_SCRIPT_EXEC_FAILED => 3015,
	WRAPPER_UNAUTHENTICATED_ID => 3016,
	WRAPPER_APP_ID_DOES_NOT_EXIST => 3027,
	WRAPPER_UNAUTHORIZED_ID => 3018,
	WRAPPER_INVALID_SESSION_ID => 3019,
	WRAPPER_CANNOT_FORK => 3020,
	
	EXTERNAL_ERROR => 4000,
	
	NEXT_ERROR => 5000,
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
	$$this{internal} = $code >= INTERNAL;
	$$this{info} = $info;
	$$this{d} = Locale::gettext->domain('schulkonsole');
	$this->{d}->dir('/usr/share/locale');
}



sub what {
	my $this = shift;

	SWITCH: {
	$this->{code} == OK and return $this->{d}->get('kein Fehler');
	$this->{code} == USER_AUTHENTICATION_FAILED
		and return $this->{d}->get('Authentifizierung fehlgeschlagen');
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
		and return $this->{d}->get('Falscher Programmaufruf');
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
