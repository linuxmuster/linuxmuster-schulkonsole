use strict;
use utf8;
use parent ("Schulkonsole::Error::Error");

package Schulkonsole::Error::SophomorixError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Schulkonsole::Error::Error);
@EXPORT_OK = qw(
	new
	what
	errstr
	fetch_error_string

	WRAPPER_ON_UNDEFINED
	WRAPPER_INVALID_USER
	WRAPPER_NO_USERS
	WRAPPER_INVALID_USERID
	WRAPPER_NO_USERIDS
	WRAPPER_NO_SUCH_DIRECTORY
	WRAPPER_INVALID_DO_COPY
	WRAPPER_INVALID_FROM
	WRAPPER_INVALID_TYPE
	WRAPPER_INVALID_ROOM
	WRAPPER_INVALID_PROJECT
	WRAPPER_INVALID_PROJECT_TEACHER
	WRAPPER_INVALID_CLASS
	WRAPPER_INVALID_CLASS_TEACHER
	WRAPPER_INVALID_SUBCLASS
	WRAPPER_INVALID_DO_ADD
	WRAPPER_INVALID_SET_PASSWORD_TYPE
	WRAPPER_INVALID_PASSWORD
	WRAPPER_INVALID_IS_GROUPS
	WRAPPER_INVALID_IS_PUBLIC
	WRAPPER_INVALID_IS_UPLOAD
	WRAPPER_INVALID_PROJECTGID
	WRAPPER_INVALID_MEMBERSCOPE
	WRAPPER_INVALID_DO_CREATE
	WRAPPER_INVALID_LONGNAME
	WRAPPER_INVALID_FILENUMBER
	WRAPPER_CANNOT_OPEN_FILE
	WRAPPER_PROCESS_RUNNING
	WRAPPER_INVALID_MODE
	WRAPPER_CHMOD_FAILED
	WRAPPER_INVALID_FLAGS
	WRAPPER_INVALID_DISKQUOTA
	WRAPPER_INVALID_MAILQUOTA
	WRAPPER_INVALID_IS_JOIN
	WRAPPER_INVALID_ACTION
	WRAPPER_INVALID_FILENAME
	WRAPPER_NO_SUCH_FILE
	WRAPPER_ACTION_NOT_SUPPORTED
	WRAPPER_INVALID_FILETYPE
	WRAPPER_INVALID_COMMIT
	WRAPPER_INVALID_PAGING
	WRAPPER_INVALID_MAILADDRESS
	WRAPPER_ERROR_SETMYMAIL
	QUOTA_NOT_ALL_MOUNTPOINTS
	INVALID_SOPHOMORIX_CONF_KEY
	INVALID_SOPHOMORIX_CONF_VALUE
);

# package constants
use constant {
	WRAPPER_ON_UNDEFINED => Schulkonsole::Error::Error::NEXT_ERROR -0,
	WRAPPER_INVALID_USER => Schulkonsole::Error::Error::NEXT_ERROR -1,
	WRAPPER_NO_USERS => Schulkonsole::Error::Error::NEXT_ERROR -2,
	WRAPPER_INVALID_USERID => Schulkonsole::Error::Error::NEXT_ERROR -3,
	WRAPPER_NO_USERIDS => Schulkonsole::Error::Error::NEXT_ERROR -4,
	WRAPPER_NO_SUCH_DIRECTORY => Schulkonsole::Error::Error::NEXT_ERROR -5,
	WRAPPER_INVALID_DO_COPY => Schulkonsole::Error::Error::NEXT_ERROR -6,
	WRAPPER_INVALID_FROM => Schulkonsole::Error::Error::NEXT_ERROR -7,
	WRAPPER_INVALID_TYPE => Schulkonsole::Error::Error::NEXT_ERROR -8,
	WRAPPER_INVALID_ROOM => Schulkonsole::Error::Error::NEXT_ERROR -9,
	WRAPPER_INVALID_PROJECT => Schulkonsole::Error::Error::NEXT_ERROR -10,
	WRAPPER_INVALID_CLASS => Schulkonsole::Error::Error::NEXT_ERROR -11,
	WRAPPER_INVALID_SUBCLASS => Schulkonsole::Error::Error::NEXT_ERROR -12,
	WRAPPER_INVALID_IS_EXAM => Schulkonsole::Error::Error::NEXT_ERROR -13,
	WRAPPER_INVALID_DO_ADD => Schulkonsole::Error::Error::NEXT_ERROR -14,
	WRAPPER_INVALID_FILE_TYPE => Schulkonsole::Error::Error::NEXT_ERROR -15,
	WRAPPER_INVALID_SET_PASSWORD_TYPE => Schulkonsole::Error::Error::NEXT_ERROR -16,
	WRAPPER_INVALID_PASSWORD => Schulkonsole::Error::Error::NEXT_ERROR -17,
	WRAPPER_INVALID_IS_GROUPS => Schulkonsole::Error::Error::NEXT_ERROR -18,
	WRAPPER_INVALID_IS_PUBLIC => Schulkonsole::Error::Error::NEXT_ERROR -19,
	WRAPPER_INVALID_IS_UPLOAD => Schulkonsole::Error::Error::NEXT_ERROR -20,
	WRAPPER_INVALID_PROJECTGID => Schulkonsole::Error::Error::NEXT_ERROR -21,
	WRAPPER_INVALID_MEMBERSCOPE => Schulkonsole::Error::Error::NEXT_ERROR -22,
	WRAPPER_INVALID_DO_CREATE => Schulkonsole::Error::Error::NEXT_ERROR -23,
	WRAPPER_INVALID_LONGNAME => Schulkonsole::Error::Error::NEXT_ERROR -24,
	WRAPPER_INVALID_FILENUMBER => Schulkonsole::Error::Error::NEXT_ERROR -25,
	WRAPPER_CANNOT_OPEN_FILE => Schulkonsole::Error::Error::NEXT_ERROR -26,
	WRAPPER_PROCESS_RUNNING => Schulkonsole::Error::Error::NEXT_ERROR -27,
	WRAPPER_INVALID_MODE => Schulkonsole::Error::Error::NEXT_ERROR -28,
	WRAPPER_CHMOD_FAILED => Schulkonsole::Error::Error::NEXT_ERROR -29,
	WRAPPER_INVALID_FLAGS => Schulkonsole::Error::Error::NEXT_ERROR -30,
	WRAPPER_INVALID_DISKQUOTA => Schulkonsole::Error::Error::NEXT_ERROR -31,
	WRAPPER_INVALID_MAILQUOTA => Schulkonsole::Error::Error::NEXT_ERROR -32,
	WRAPPER_INVALID_IS_JOIN => Schulkonsole::Error::Error::NEXT_ERROR -33,
	WRAPPER_INVALID_ACTION => Schulkonsole::Error::Error::NEXT_ERROR -34,
	WRAPPER_INVALID_FILENAME => Schulkonsole::Error::Error::NEXT_ERROR -35,
	WRAPPER_NO_SUCH_FILE => Schulkonsole::Error::Error::NEXT_ERROR -36,
	WRAPPER_ACTION_NOT_SUPPORTED => Schulkonsole::Error::Error::NEXT_ERROR -37,
	WRAPPER_INVALID_FILETYPE => Schulkonsole::Error::Error::NEXT_ERROR - 38,
	WRAPPER_INVALID_CLASS_TEACHER => Schulkonsole::Error::Error::NEXT_ERROR - 39,
	WRAPPER_INVALID_PROJECT_TEACHER => Schulkonsole::Error::Error::NEXT_ERROR - 40,
	WRAPPER_INVALID_COMMIT => Schulkonsole::Error::Error::NEXT_ERROR - 41,
	WRAPPER_INVALID_PAGING => Schulkonsole::Error::Error::NEXT_ERROR - 42,
	WRAPPER_INVALID_MAILADDRESS => Schulkonsole::Error::Error::NEXT_ERROR -43,
	WRAPPER_ERROR_SETMYMAIL => Schulkonsole::Error::Error::NEXT_ERROR -44,
	QUOTA_NOT_ALL_MOUNTPOINTS => Schulkonsole::Error::Error::NEXT_ERROR - 45,
	INVALID_SOPHOMORIX_CONF_KEY => Schulkonsole::Error::Error::NEXT_ERROR - 46,
	INVALID_SOPHOMORIX_CONF_VALUE => Schulkonsole::Error::Error::NEXT_ERROR - 47,
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
	$this->{code} == WRAPPER_ON_UNDEFINED
		and return $this->{d}->get('on muss 1 oder 0 sein');
	$this->{code} == WRAPPER_INVALID_USER
		and return $this->{d}->get('Ungültiger Benutzer');
	$this->{code} == WRAPPER_NO_USERS
		and return $this->{d}->get('Keine Benutzer');
	$this->{code} == WRAPPER_INVALID_USERID
		and return $this->{d}->get('Ungültige Benutzer-ID');
	$this->{code} == WRAPPER_NO_USERIDS
		and return $this->{d}->get('Keine Benutzer-IDs');
	$this->{code} == WRAPPER_NO_SUCH_DIRECTORY
		and return $this->{d}->get('Verzeichnis nicht gefunden');
	$this->{code} == WRAPPER_INVALID_ROOM
		and return $this->{d}->get('Ungültiger Raumbezeichner');
	$this->{code} == WRAPPER_INVALID_DO_COPY
		and return $this->{d}->get('Erwarte 1 oder 0 für do_copy');
	$this->{code} == WRAPPER_INVALID_FROM
		and return $this->{d}->get('Erwarte numerische Angabe für "from"');
	$this->{code} == WRAPPER_INVALID_TYPE
		and return $this->{d}->get('Erwarte numerische Angabe für "type"');
	$this->{code} == WRAPPER_INVALID_ROOM
		and return $this->{d}->get('Ungültiger Raum');
	$this->{code} == WRAPPER_INVALID_PROJECT
		and return $this->{d}->get('Ungültiges Projekt');
	$this->{code} == WRAPPER_INVALID_CLASS
		and return $this->{d}->get('Ungültige Klassen-GID');
	$this->{code} == WRAPPER_INVALID_SUBCLASS
		and return $this->{d}->get('Ungültige Subklasse');
	$this->{code} == WRAPPER_INVALID_DO_ADD
		and return $this->{d}->get('Erwarte 1 oder 0 fuer do_add');
	$this->{code} == WRAPPER_INVALID_FILE_TYPE
		and return $this->{d}->get('Erwarte 0 (PDF) oder 1 (CSV) für filetype');
	$this->{code} == WRAPPER_INVALID_SET_PASSWORD_TYPE
		and return $this->{d}->get('Erwarte 0 (reset), 1 (passwd) oder 3 (random) für type');
	$this->{code} == WRAPPER_INVALID_PASSWORD
		and return $this->{d}->get('Ungültiger Wert für password');
	$this->{code} == WRAPPER_INVALID_IS_GROUPS
		and return $this->{d}->get('Erwarte 1 oder 0 für is_groups');
	$this->{code} == WRAPPER_INVALID_IS_PUBLIC
		and return $this->{d}->get('Erwarte 1 oder 0 für is_public');
	$this->{code} == WRAPPER_INVALID_IS_UPLOAD
		and return $this->{d}->get('Erwarte 1 oder 0 für is_upload');
	$this->{code} == WRAPPER_INVALID_PROJECTGID
		and return $this->{d}->get('Ungültiger Wert für projectgid');
	$this->{code} == WRAPPER_INVALID_MEMBERSCOPE
		and return $this->{d}->get('Erwarte 0, 1, 2 oder 3 für scope');
	$this->{code} == WRAPPER_INVALID_DO_CREATE
		and return $this->{d}->get('Erwarte 1 oder 0 fuer do_create');
	$this->{code} == WRAPPER_INVALID_LONGNAME
		and return $this->{d}->get('Ungültiger Wert für longname');
	$this->{code} == WRAPPER_INVALID_FILENUMBER
		and return $this->{d}->get('Ungültiger Wert für number');
	$this->{code} == WRAPPER_PROCESS_RUNNING
		and return $this->{d}->get('Prozess läuft schon');
	$this->{code} == WRAPPER_INVALID_MODE
		and return $this->{d}->get('Erwarte 0, 1 oder 2 für mode');
	$this->{code} == WRAPPER_CHMOD_FAILED
		and return $this->{d}->get('Konnte Berechtigung nicht ändern');
	$this->{code} == WRAPPER_INVALID_FLAGS
		and return $this->{d}->get('Erwarte 1 bis 7 für flags');
	$this->{code} == WRAPPER_INVALID_DISKQUOTA
		and return $this->{d}->get('Ungültiger Wert für diskquota');
	$this->{code} == WRAPPER_INVALID_MAILQUOTA
		and return $this->{d}->get('Ungültiger Wert für mailquota');
	$this->{code} == WRAPPER_INVALID_IS_JOIN
		and return $this->{d}->get('Erwarte 1 oder 0 für is_open');
	$this->{code} == WRAPPER_INVALID_ACTION
		and return $this->{d}->get('Ungültiger Wert, action sollte eine Zahl sein');
	$this->{code} == WRAPPER_INVALID_FILENAME
		and return $this->{d}->get('Ungültiger Wert für Dateiname');
	$this->{code} == WRAPPER_NO_SUCH_FILE
		and return $this->{d}->get('Konnte Datei nicht finden');
	$this->{code} == WRAPPER_ACTION_NOT_SUPPORTED
		and return $this->{d}->get('Erwarte 1,2 oder 3 für action');
	$this->{code} == WRAPPER_INVALID_FILETYPE
		and return $this->{d}->get('Erwarte Verzeichnis, fand Datei (oder umgekehrt)');
	$this->{code} == WRAPPER_INVALID_MAILADDRESS
		and return $this->{d}->get('Die angegebene Mailadresse ist ungültig');
	$this->{code} == WRAPPER_ERROR_SETMYMAIL
		and return $this->{d}->get('Die Mailadresse konnte nicht gespeichert werden.');
	$this->{code} == QUOTA_NOT_ALL_MOUNTPOINTS
		and return $this->{d}->get('Nicht alle Einhängepunkte(mount points) gefunden');
	$this->{code} = INVALID_SOPHOMORIX_CONF_KEY
		and return $this->{d}->get('Der Name ist ungültig für die Datei sophomorix.conf.');
	$this->{code} = INVALID_SOPHOMORIX_CONF_VALUE
		and return $this->{d}->get('Der Wert für diese Einstellung ungültig für die Datei sophomorix.conf.');
	};
	
	return $this->SUPER::what();
}

sub fetch_error_string {
	my $this = shift;
	my $extcode = shift;
	
	return Sophomorix::SophomorixAPI::fetch_error_string($extcode);
}

1;
