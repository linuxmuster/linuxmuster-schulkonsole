use strict;
use utf8;
use parent ("Error");

package Schulkonsole::Error::SophomorixError;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter Error);
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
);

# package constants
use constant {
	WRAPPER_ON_UNDEFINED => Schulkonsole::Error::Error::NEXT_ERROR +80,
	WRAPPER_INVALID_USER => Schulkonsole::Error::Error::NEXT_ERROR +81,
	WRAPPER_NO_USERS => Schulkonsole::Error::Error::NEXT_ERROR +82,
	WRAPPER_INVALID_USERID => Schulkonsole::Error::Error::NEXT_ERROR +83,
	WRAPPER_NO_USERIDS => Schulkonsole::Error::Error::NEXT_ERROR +84,
	WRAPPER_NO_SUCH_DIRECTORY => Schulkonsole::Error::Error::NEXT_ERROR +85,
	WRAPPER_INVALID_DO_COPY => Schulkonsole::Error::Error::NEXT_ERROR +86,
	WRAPPER_INVALID_FROM => Schulkonsole::Error::Error::NEXT_ERROR +87,
	WRAPPER_INVALID_TYPE => Schulkonsole::Error::Error::NEXT_ERROR +88,
	WRAPPER_INVALID_ROOM => Schulkonsole::Error::Error::NEXT_ERROR +89,
	WRAPPER_INVALID_PROJECT => Schulkonsole::Error::Error::NEXT_ERROR +90,
	WRAPPER_INVALID_CLASS => Schulkonsole::Error::Error::NEXT_ERROR +91,
	WRAPPER_INVALID_SUBCLASS => Schulkonsole::Error::Error::NEXT_ERROR +92,
	WRAPPER_INVALID_IS_EXAM => Schulkonsole::Error::Error::NEXT_ERROR +93,
	WRAPPER_INVALID_DO_ADD => Schulkonsole::Error::Error::NEXT_ERROR +94,
	WRAPPER_INVALID_FILE_TYPE => Schulkonsole::Error::Error::NEXT_ERROR +95,
	WRAPPER_INVALID_SET_PASSWORD_TYPE => Schulkonsole::Error::Error::NEXT_ERROR +96,
	WRAPPER_INVALID_PASSWORD => Schulkonsole::Error::Error::NEXT_ERROR +97,
	WRAPPER_INVALID_IS_GROUPS => Schulkonsole::Error::Error::NEXT_ERROR +98,
	WRAPPER_INVALID_IS_PUBLIC => Schulkonsole::Error::Error::NEXT_ERROR +99,
	WRAPPER_INVALID_IS_UPLOAD => Schulkonsole::Error::Error::NEXT_ERROR +100,
	WRAPPER_INVALID_PROJECTGID => Schulkonsole::Error::Error::NEXT_ERROR +101,
	WRAPPER_INVALID_MEMBERSCOPE => Schulkonsole::Error::Error::NEXT_ERROR +102,
	WRAPPER_INVALID_DO_CREATE => Schulkonsole::Error::Error::NEXT_ERROR +103,
	WRAPPER_INVALID_LONGNAME => Schulkonsole::Error::Error::NEXT_ERROR +104,
	WRAPPER_INVALID_FILENUMBER => Schulkonsole::Error::Error::NEXT_ERROR +105,
	WRAPPER_CANNOT_OPEN_FILE => Schulkonsole::Error::Error::NEXT_ERROR +106,
	WRAPPER_PROCESS_RUNNING => Schulkonsole::Error::Error::NEXT_ERROR +107,
	WRAPPER_INVALID_MODE => Schulkonsole::Error::Error::NEXT_ERROR +108,
	WRAPPER_CHMOD_FAILED => Schulkonsole::Error::Error::NEXT_ERROR +109,
	WRAPPER_INVALID_FLAGS => Schulkonsole::Error::Error::NEXT_ERROR +110,
	WRAPPER_INVALID_DISKQUOTA => Schulkonsole::Error::Error::NEXT_ERROR +111,
	WRAPPER_INVALID_MAILQUOTA => Schulkonsole::Error::Error::NEXT_ERROR +112,
	WRAPPER_INVALID_IS_JOIN => Schulkonsole::Error::Error::NEXT_ERROR +113,
	WRAPPER_INVALID_ACTION => Schulkonsole::Error::Error::NEXT_ERROR +114,
	WRAPPER_INVALID_FILENAME => Schulkonsole::Error::Error::NEXT_ERROR +115,
	WRAPPER_NO_SUCH_FILE => Schulkonsole::Error::Error::NEXT_ERROR +116,
	WRAPPER_ACTION_NOT_SUPPORTED => Schulkonsole::Error::Error::NEXT_ERROR +117,
	WRAPPER_INVALID_FILETYPE => Schulkonsole::Error::Error::NEXT_ERROR + 118,
	WRAPPER_INVALID_CLASS_TEACHER => Schulkonsole::Error::Error::NEXT_ERROR + 119,
	WRAPPER_INVALID_PROJECT_TEACHER => Schulkonsole::Error::Error::NEXT_ERROR + 120,
	WRAPPER_INVALID_COMMIT => Schulkonsole::Error::Error::NEXT_ERROR + 121,
	WRAPPER_INVALID_PAGING => Schulkonsole::Error::Error::NEXT_ERROR + 122,
	WRAPPER_INVALID_MAILADDRESS => Schulkonsole::Error::Error::NEXT_ERROR +123,
	WRAPPER_ERROR_SETMYMAIL => Schulkonsole::Error::Error::NEXT_ERROR +124,
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
		and return $this->{d}->get('Ungueltiger Benutzer');
	$this->{code} == WRAPPER_NO_USERS
		and return $this->{d}->get('Keine Benutzer');
	$this->{code} == WRAPPER_INVALID_USERID
		and return $this->{d}->get('Ungueltige Benutzer-ID');
	$this->{code} == WRAPPER_NO_USERIDS
		and return $this->{d}->get('Keine Benutzer-IDs');
	$this->{code} == WRAPPER_NO_SUCH_DIRECTORY
		and return $this->{d}->get('Verzeichnis nicht gefunden');
	$this->{code} == WRAPPER_INVALID_ROOM
		and return $this->{d}->get('Ungueltiger Raumbezeichner');
	$this->{code} == WRAPPER_INVALID_DO_COPY
		and return $this->{d}->get('Erwarte 1 oder 0 fuer do_copy');
	$this->{code} == WRAPPER_INVALID_FROM
		and return $this->{d}->get('Erwarte numerische Angabe fuer "from"');
	$this->{code} == WRAPPER_INVALID_TYPE
		and return $this->{d}->get('Erwarte numerische Angabe fuer "type"');
	$this->{code} == WRAPPER_INVALID_ROOM
		and return $this->{d}->get('Ungueltiger Raum');
	$this->{code} == WRAPPER_INVALID_PROJECT
		and return $this->{d}->get('Ungueltiges Projekt');
	$this->{code} == WRAPPER_INVALID_CLASS
		and return $this->{d}->get('Ungueltige Klassen-GID');
	$this->{code} == WRAPPER_INVALID_SUBCLASS
		and return $this->{d}->get('Ungueltige Subklasse');
	$this->{code} == WRAPPER_INVALID_DO_ADD
		and return $this->{d}->get('Erwarte 1 oder 0 fuer do_add');
	$this->{code} == WRAPPER_INVALID_FILE_TYPE
		and return $this->{d}->get('Erwarte 0 (PDF) oder 1 (CSV) fuer filetype');
	$this->{code} == WRAPPER_INVALID_SET_PASSWORD_TYPE
		and return $this->{d}->get('Erwarte 0 (reset), 1 (passwd) oder 3 (random) fuer type');
	$this->{code} == WRAPPER_INVALID_PASSWORD
		and return $this->{d}->get('Ungueltiger Wert fuer password');
	$this->{code} == WRAPPER_INVALID_IS_GROUPS
		and return $this->{d}->get('Erwarte 1 oder 0 fuer is_groups');
	$this->{code} == WRAPPER_INVALID_IS_PUBLIC
		and return $this->{d}->get('Erwarte 1 oder 0 fuer is_public');
	$this->{code} == WRAPPER_INVALID_IS_UPLOAD
		and return $this->{d}->get('Erwarte 1 oder 0 fuer is_upload');
	$this->{code} == WRAPPER_INVALID_PROJECTGID
		and return $this->{d}->get('Ungueltiger Wert fuer projectgid');
	$this->{code} == WRAPPER_INVALID_MEMBERSCOPE
		and return $this->{d}->get('Erwarte 0, 1, 2 oder 3 fuer scope');
	$this->{code} == WRAPPER_INVALID_DO_CREATE
		and return $this->{d}->get('Erwarte 1 oder 0 fuer do_create');
	$this->{code} == WRAPPER_INVALID_LONGNAME
		and return $this->{d}->get('Ungueltiger Wert fuer longname');
	$this->{code} == WRAPPER_INVALID_FILENUMBER
		and return $this->{d}->get('Ungueltiger Wert fuer number');
	$this->{code} == WRAPPER_PROCESS_RUNNING
		and return $this->{d}->get('Prozess laeuft schon');
	$this->{code} == WRAPPER_INVALID_MODE
		and return $this->{d}->get('Erwarte 0, 1 oder 2 fuer mode');
	$this->{code} == WRAPPER_CHMOD_FAILED
		and return $this->{d}->get('Konnte Berechtigung nicht aendern');
	$this->{code} == WRAPPER_INVALID_FLAGS
		and return $this->{d}->get('Erwarte 1 bis 7 fuer flags');
	$this->{code} == WRAPPER_INVALID_DISKQUOTA
		and return $this->{d}->get('Ungueltiger Wert fuer diskquota');
	$this->{code} == WRAPPER_INVALID_MAILQUOTA
		and return $this->{d}->get('Ungueltiger Wert fuer mailquota');
	$this->{code} == WRAPPER_INVALID_IS_JOIN
		and return $this->{d}->get('Erwarte 1 oder 0 fuer is_open');
	$this->{code} == WRAPPER_INVALID_ACTION
		and return $this->{d}->get('Ungueltiger Wert, action sollte eine Zahl sein');
	$this->{code} == WRAPPER_INVALID_FILENAME
		and return $this->{d}->get('Ungueltiger Wert fuer Dateiname');
	$this->{code} == WRAPPER_NO_SUCH_FILE
		and return $this->{d}->get('Konnte Datei nicht finden');
	$this->{code} == WRAPPER_ACTION_NOT_SUPPORTED
		and return $this->{d}->get('Erwarte 1,2 oder 3 fuer action');
	$this->{code} == WRAPPER_INVALID_FILETYPE
		and return $this->{d}->get('Erwarte Verzeichnis, fand Datei (oder umgekehrt)');
	$this->{code} == WRAPPER_INVALID_MAILADDRESS
		and return $this->{d}->get('Die angegebene Mailadresse ist ungültig');
	$this->{code} == WRAPPER_ERROR_SETMYMAIL
		and return $this->{d}->get('Die Mailadresse konnte nicht gespeichert werden.');
	};
	
	return SUPER::what();
}

sub fetch_error_string {
	my $this = shift;
	my $extcode = shift;
	
	return Sophomorix::SophomorixAPI::fetch_error_string($extcode);
}

1;
