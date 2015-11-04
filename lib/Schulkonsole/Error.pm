use strict;
use Schulkonsole::Error::Cyrus;
use Schulkonsole::Error::Files;
use Schulkonsole::Error::Firewall;
use Schulkonsole::Error::Radius;
use Schulkonsole::Error::Linbo;
use Schulkonsole::Error::OVPN;
use Schulkonsole::Error::Printer;
use Schulkonsole::Error::Sophomorix;
use Schulkonsole::Error::User;
use Schulkonsole::Error::Horde;
use Schulkonsole::Error::Debconf;

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
};

use overload
	'""' => \&errstr;





sub new {
	my $class = shift;
	my $code = shift;
	my $info = @_ ? \@_ : undef;

	my $this = {
		code => $code,
		internal => $code >= INTERNAL,
		info => $info,
	};

	bless $this, $class;

	return $this;
}




sub what {
	my $this = shift;

	SWITCH: {
	$this->{code} == OK and return 'kein Fehler';
	$this->{code} == USER_AUTHENTICATION_FAILED
		and return 'Authentifizierung fehlgeschlagen';
	$this->{code} == USER_PASSWORD_MISMATCH
		and return 'Neues Passwort nicht richtig wiederholt';
	$this->{code} == UNKNOWN_ROOM
		and return 'Raum ist unbekannt';
	$this->{code} == UNKNOWN_GROUP
		and return 'Klasse/Projekt ist unbekannt';
	$this->{code} == QUOTA_NOT_ALL_MOUNTPOINTS
		and return 'Für Diskquota müssen alle oder keine Felder ausgefüllt sein';
	$this->{code} == PUBLIC_BG_ERROR
		and return 'Fehler im Hintergrundprozess: ' . ${ $this->{info} }[0];
	$this->{code} == Schulkonsole::Error::Linbo::START_CONF_ERROR
		and return "Fehler in der Konfiguration";
	$this->{code} == INTERNAL_BG_ERROR
		and return 'Fehler im Hintergrundprozess';
	$this->{code} == DB_PREPARE_FAILED
		and return 'Prepare fehlgeschlagen';
	$this->{code} == DB_EXECUTE_FAILED
		and return 'Execute fehlgeschlagen';
	$this->{code} == DB_FETCH_FAILED
		and return 'Fetch fehlgeschlagen';
	$this->{code} == UNKNOWN_PASSWORD_ENCRYPTION
		and return 'Unbekannte Passwortverschluesselung';
	$this->{code} == DB_USER_DOES_NOT_EXIST
		and return 'Benutzer existiert nicht';
	$this->{code} == DB_NO_WORKSTATION_USERS
		and return 'Keine Workstationbenutzer';
	(   $this->{code} == CANNOT_OPEN_FILE
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_CANNOT_OPEN_FILE
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_CANNOT_OPEN_FILE
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_CANNOT_OPEN_FILE)
		and return 'Kann Datei nicht oeffnen';
	$this->{code} == FILE_FORMAT_ERROR
		and return 'Datei hat falsches Format';
	$this->{code} == WRAPPER_EXEC_FAILED
		and return 'Wrapperaufruf fehlgeschlagen';
	$this->{code} == WRAPPER_BROKEN_PIPE_OUT
		and return 'Datenuebertragung (schreiben) unterbrochen';
	$this->{code} == WRAPPER_BROKEN_PIPE_IN
		and return 'Datenuebertragung (lesen) unterbrochen';
	(   $this->{code} == Schulkonsole::Error::User::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Horde::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Radius::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Printer::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_PROGRAM_ERROR
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_PROGRAM_ERROR)
		and return 'Programmaufruf fehlgeschlagen';
	(   $this->{code} == Schulkonsole::Error::User::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Horde::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Radius::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Printer::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Cyrus::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_UNAUTHORIZED_UID
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_UNAUTHORIZED_UID)
		and return 'Nicht autorisierter Aufrufer';
	(    $this->{code} == Schulkonsole::Error::User::WRAPPER_INVALID_UID
	or $this->{code} == Schulkonsole::Error::Horde::WRAPPER_INVALID_UID
	or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_INVALID_UID)
		and return 'Wechsel zu diesem Benutzer nicht erlaubt';
	(    $this->{code} == Schulkonsole::Error::User::WRAPPER_SETUID_FAILED
	or $this->{code} == Schulkonsole::Error::Horde::WRAPPER_SETUID_FAILED)
		and return 'Wechsel zu diesem Benutzer nicht moeglich';
	(   $this->{code} == Schulkonsole::Error::User::WRAPPER_INVALID_SCRIPT
	 or $this->{code} == Schulkonsole::Error::Horde::WRAPPER_INVALID_SCRIPT
	 or $this->{code} == Schulkonsole::Error::Cyrus::WRAPPER_INVALID_SCRIPT)
		and return 'Skript nicht vorhanden';
	(   $this->{code} == Schulkonsole::Error::User::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Horde::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Radius::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Printer::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Cyrus::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_SCRIPT_EXEC_FAILED
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_SCRIPT_EXEC_FAILED)
		and return 'Skriptaufruf fehlgeschlagen';
	(   $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::Radius::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::Printer::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_UNAUTHENTICATED_ID
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_UNAUTHENTICATED_ID)
		and return 'Authentifizierung fehlgeschlagen nach ID';
	(   $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::Radius::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::Printer::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_APP_ID_DOES_NOT_EXIST
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_APP_ID_DOES_NOT_EXIST)
		and return 'Programm-ID unbekannt';
	(   $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_UNAUTHORIZED_ID
	 or $this->{code} == Schulkonsole::Error::Radius::WRAPPER_UNAUTHORIZED_ID
	 or $this->{code} == Schulkonsole::Error::Printer::WRAPPER_UNAUTHORIZED_ID
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_UNAUTHORIZED_ID
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_UNAUTHORIZED_ID
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_UNAUTHORIZED_ID
	 or $this->{code} == Schulkonsole::Error::Linbo::WRAPPER_UNAUTHORIZED_ID)
		and return 'Nicht autorisierter Aufrufer nach ID';
	$this->{code} == Schulkonsole::Error::Files::WRAPPER_INVALID_SESSION_ID
		and return 'Ungueltige Session-ID';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_MAC
		and return 'Ungueltige MAC-Adresse';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_NO_MACS
		and return 'Keine MAC-Adressen';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_HOST
		and return 'Ungueltiger Host';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_NO_HOSTS
		and return 'Keine Hosts';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_ROOM
		and return 'Ungueltige Raumbezeichnung';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_LESSONMODE
		and return 'Ungueltiger Modus fuer Unterricht';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_LESSONTIME
		and return 'Ungueltige Zeitangabe fuer Unterrichtsende';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_WRITE_ROOMFILE
		and return 'Raumdatei kann nicht geschrieben werden';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_READ_ROOMFILE
		and return 'Raumdatei kann nicht gelesen werden';
	$this->{code} == Schulkonsole::Error::Firewall::WRAPPER_INVALID_ROOM_SCOPE
		and return 'Erwarte 0 oder 1 fuer scope';
	(   $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_FORK
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_CANNOT_FORK
	 or $this->{code} == Schulkonsole::Error::Debconf::WRAPPER_CANNOT_FORK
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_CANNOT_FORK)
		and return 'Fork nicht moeglich';
	(   $this->{code} == Schulkonsole::Error::Printer::WRAPPER_CANNOT_OPEN_PRINTERSCONF
	 or $this->{code} == Schulkonsole::Error::Firewall::WRAPPER_CANNOT_OPEN_PRINTERSCONF)
		and return 'Kann printers.conf nicht oeffnen';
	$this->{code} == Schulkonsole::Error::Printer::WRAPPER_INVALID_PRINTER_NAME
		and return 'Ungueltiger Druckername';
	$this->{code} == Schulkonsole::Error::Printer::WRAPPER_NO_PRINTERS
		and return 'Keine Drucker';
	$this->{code} == Schulkonsole::Error::Printer::WRAPPER_INVALID_USER
		and return 'Ungueltiger Druckernutzer';
	$this->{code} == Schulkonsole::Error::Printer::WRAPPER_INVALID_PAGES
		and return 'Ungueltige Daten fuer genutzte Druckquota';
	$this->{code} == Schulkonsole::Error::Printer::WRAPPER_INVALID_MAX_PAGES
		and return 'Ungueltige Daten fuer Druckquota';
	$this->{code} == Schulkonsole::Error::Printer::WRAPPER_UNEXPECTED_DATA
		and return 'Unerwartete Programmausgabe';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_ON_UNDEFINED
		and return 'on muss 1 oder 0 sein';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_USER
		and return 'Ungueltiger Benutzer';
	(   $this->{code} == Schulkonsole::Error::Printer::WRAPPER_NO_USERS
	 or $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_NO_USERS)
		and return 'Keine Benutzer';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_USERID
		and return 'Ungueltige Benutzer-ID';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_NO_USERIDS
		and return 'Keine Benutzer-IDs';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_NO_SUCH_DIRECTORY
		and return 'Verzeichnis nicht gefunden';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_ROOM
		and return 'Ungueltiger Raumbezeichner';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_DO_COPY
		and return 'Erwarte 1 oder 0 fuer do_copy';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_FROM
		and return 'Erwarte numerische Angabe fuer "from"';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_TYPE
		and return 'Erwarte numerische Angabe fuer "type"';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_ROOM
		and return 'Ungueltiger Raum';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_PROJECT
		and return 'Ungueltiges Projekt';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_CLASS
		and return 'Ungueltige Klassen-GID';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_SUBCLASS
		and return 'Ungueltige Subklasse';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_DO_ADD
		and return 'Erwarte 1 oder 0 fuer do_add';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_FILE_TYPE
		and return 'Erwarte 0 (PDF) oder 1 (CSV) fuer filetype';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_SET_PASSWORD_TYPE
		and return 'Erwarte 0 (reset), 1 (passwd) oder 3 (random) fuer type';
	(   $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_PASSWORD
	 or $this->{code} == Schulkonsole::Error::OVPN::WRAPPER_INVALID_PASSWORD)
		and return 'Ungueltiger Wert fuer password';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_IS_GROUPS
		and return 'Erwarte 1 oder 0 fuer is_groups';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_IS_PUBLIC
		and return 'Erwarte 1 oder 0 fuer is_public';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_IS_UPLOAD
		and return 'Erwarte 1 oder 0 fuer is_upload';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_PROJECTGID
		and return 'Ungueltiger Wert fuer projectgid';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_MEMBERSCOPE
		and return 'Erwarte 0, 1, 2 oder 3 fuer scope';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_DO_CREATE
		and return 'Erwarte 1 oder 0 fuer do_create';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_LONGNAME
		and return 'Ungueltiger Wert fuer longname';
	$this->{code} == Schulkonsole::Error::Cyrus::WRAPPER_NO_CYRUS_USER
		and return 'Benutzer "cyrus" gibt es nicht';
	$this->{code} == Schulkonsole::Error::Cyrus::WRAPPER_INVALID_EUID
		and return 'wrapper-cyrus gehoert nicht Benutzer "cyrus" oder SUID nicht gesetzt';
	$this->{code} == Schulkonsole::Error::Linbo::WRAPPER_INVALID_GROUP
		and return 'Ungueltiger Gruppenname';
	$this->{code} == Schulkonsole::Error::Linbo::WRAPPER_INVALID_FILENAME
		and return 'Ungueltiger Dateiname';
	$this->{code} == Schulkonsole::Error::Linbo::WRAPPER_INVALID_IS_EXAMPLE
		and return 'Erwarte 1 oder 0 fuer is_example';
	$this->{code} == Schulkonsole::Error::Linbo::WRAPPER_INVALID_IMAGE
		and return 'Ungueltiger Image-Dateiname';
	$this->{code} == Schulkonsole::Error::Linbo::WRAPPER_INVALID_ACTION
		and return 'action muss 0, 1 oder 2 sein';
	(   $this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_FILENUMBER
	 or $this->{code} == Schulkonsole::Error::Files::WRAPPER_INVALID_FILENUMBER)
		and return 'Ungueltiger Wert fuer number';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_PROCESS_RUNNING
		and return 'Prozess laeuft schon';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_MODE
		and return 'Erwarte 0, 1 oder 2 fuer mode';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_CHMOD_FAILED
		and return 'Konnte Berechtigung nicht aendern';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_FLAGS
		and return 'Erwarte 1 bis 7 fuer flags';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_DISKQUOTA
		and return 'Ungueltiger Wert fuer diskquota';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_MAILQUOTA
		and return 'Ungueltiger Wert fuer mailquota';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_IS_JOIN
		and return 'Erwarte 1 oder 0 fuer is_open';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_ACTION
		and return 'Ungueltiger Wert, action sollte eine Zahl sein';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_FILENAME
		and return 'Ungueltiger Wert fuer Dateiname';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_NO_SUCH_FILE
		and return 'Konnte Datei nicht finden';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_ACTION_NOT_SUPPORTED
		and return 'Erwarte 1,2 oder 3 fuer action';
	$this->{code} == Schulkonsole::Error::Sophomorix::WRAPPER_INVALID_FILETYPE
		and return 'Erwarte Verzeichnis, fand Datei (oder umgekehrt)';
	$this->{code} == Schulkonsole::Error::Debconf::WRAPPER_INVALID_SECTION
		and return 'Ungueltiger Debconf-Bereich';
	$this->{code} == Schulkonsole::Error::Debconf::WRAPPER_INVALID_NAME
		and return 'Ungueltiger Debconf-Name';
	$this->{code} == Schulkonsole::Error::Debconf::WRAPPER_INVALID_REQUEST
		and return 'Dieser Bereich/Name darf nicht abgefragt werden';
	$this->{what}
		and return $this->{what};

	return 'Unbekannter Fehler ' . $this->{code}
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
