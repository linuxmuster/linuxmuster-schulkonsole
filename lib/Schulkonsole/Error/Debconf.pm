use strict;

package Schulkonsole::Error::Debconf;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 0.16;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	OK
	WRAPPER_ERROR_BASE
	WRAPPER_GENERAL_ERROR
	WRAPPER_PROGRAM_ERROR
	WRAPPER_UNAUTHORIZED_UID
	WRAPPER_CANNOT_FORK
	WRAPPER_SCRIPT_EXEC_FAILED
	WRAPPER_UNAUTHENTICATED_ID
	WRAPPER_APP_ID_DOES_NOT_EXIST
	WRAPPER_UNAUTHORIZED_ID
	WRAPPER_INVALID_UID
	WRAPPER_INVALID_SECTION
	WRAPPER_INVALID_NAME
	WRAPPER_INVALID_REQUEST
);

# package constants
use constant {
	OK => 0,

	WRAPPER_ERROR_BASE => 15000,
	WRAPPER_GENERAL_ERROR => 15000 -1,
	WRAPPER_PROGRAM_ERROR => 15000 -2,
	WRAPPER_UNAUTHORIZED_UID => 15000 -3,
	WRAPPER_SCRIPT_EXEC_FAILED => 15000 -6,
	WRAPPER_INVALID_SESSION_ID => 15000 -10,
	WRAPPER_UNAUTHENTICATED_ID => 15000 -32,
	WRAPPER_APP_ID_DOES_NOT_EXIST => 15000 -33,
	WRAPPER_UNAUTHORIZED_ID => 15000 -34,
	WRAPPER_CANNOT_FORK => 15000 -44,
	WRAPPER_INVALID_UID => 1500 -105,
	WRAPPER_INVALID_SECTION => 15000 -107,
	WRAPPER_INVALID_NAME => 15000 -108,
	WRAPPER_INVALID_REQUEST => 15000 - 109,
};



1;
