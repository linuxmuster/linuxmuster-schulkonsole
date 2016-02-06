use strict;
use POSIX;
eval {
	require Locale::gettext;
	Locale::gettext->require_version(1.04);
};
if ($@) {
	require Schulkonsole::Gettext;
}

package Schulkonsole::Error;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.06;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	new
	what
	errstr

	OK
	USER_AUTHENTICATION_FAILED
	USER_PASSWORD_MISMATCH
	UNKNOWN_ROOM
	UNKNOWN_GROUP
	QUOTA_NOT_ALL_MOUNTPOINTS
	PUBLIC_BG_ERROR
	INTERNAL_BG_ERROR
	DB_PREPARE_FAILED
	DB_EXECUTE_FAILED
	DB_FETCH_FAILED
	UNKNOWN_PASSWORD_ENCRYPTION
	DB_USER_DOES_NOT_EXIST
	DB_NO_WORKSTATION_USERS
	CANNOT_OPEN_FILE
	FILE_FORMAT_ERROR
	WRAPPER_EXEC_FAILED
	WRAPPER_BROKEN_PIPE_OUT
	WRAPPER_BROKEN_PIPE_IN
	WRAPPER_WRONG,
	WRAPPER_UNKNOWN,
);

# package constants
use constant {
	OK => 0,

	USER_AUTHENTICATION_FAILED  => 1,
	USER_PASSWORD_MISMATCH => 2,


	UNKNOWN_ROOM => 3,
	UNKNOWN_GROUP => 4,

	QUOTA_NOT_ALL_MOUNTPOINTS => 10,

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

	WRAPPER_EXEC_FAILED => 3001,
	WRAPPER_BROKEN_PIPE_OUT => 3002,
	WRAPPER_BROKEN_PIPE_IN => 3003,
	WRAPPER_WRONG => 3004,
	WRAPPER_UNKNOWN => 3005,
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
	$this->{code} == USER_PASSWORD_MISMATCH
		and return $this->{d}->get('Neues Passwort nicht richtig wiederholt');
	$this->{code} == UNKNOWN_ROOM
		and return $this->{d}->get('Raum ist unbekannt');
	$this->{code} == UNKNOWN_GROUP
		and return $this->{d}->get('Klasse/Projekt ist unbekannt');
	$this->{code} == QUOTA_NOT_ALL_MOUNTPOINTS
		and return $this->{d}->get('Für Diskquota müssen alle oder keine Felder ausgefüllt sein');
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
	(   $this->{code} == CANNOT_OPEN_FILE)
		and return $this->{d}->get('Kann Datei nicht oeffnen');
	$this->{code} == FILE_FORMAT_ERROR
		and return $this->{d}->get('Datei hat falsches Format');
	$this->{code} == WRAPPER_EXEC_FAILED
		and return $this->{d}->get('Wrapperaufruf fehlgeschlagen');
	$this->{code} == WRAPPER_BROKEN_PIPE_OUT
		and return $this->{d}->get('Datenuebertragung (schreiben) unterbrochen');
	$this->{code} == WRAPPER_BROKEN_PIPE_IN
		and return $this->{d}->get('Datenuebertragung (lesen) unterbrochen');
	$this->{what}
		and return $this->{what};

	return $this->{d}->get('Unbekannter Fehler ') . $this->{code}
		. ' [' . join(', ', (caller(2))[1..3]) . ']'; 
	}
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
