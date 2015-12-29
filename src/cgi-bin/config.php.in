<?php
unset($CFG);
$CFG = new stdClass();

$CFG->locale       = 'de_DE.UTF-8';

$CFG->cgibase      = '/usr/lib/schulkonsole/';
$CFG->libbase      = '/usr/share/schulkonsole/';
$CFG->varbase      = '/var/lib/schulkonsole/';

$CFG->cgidir       = $CFG->cgibase . 'cgi-bin/';
$CFG->wrapperdir   = $CFG->cgibase . 'bin/';
$CFG->libdir       = $CFG->libbase . 'Schulkonsole/';
$CFG->shtmldir     = $CFG->libbase . 'shtml/';

$CFG->SESSION_FILE = $CFG->varbase . '/cgisess_';

set_exception_handler(function($e) {
	echo 'Unerwarteter Fehler: ' . $e;
	die;
});

spl_autoload_register(function($class) use($CFG) {
	if(!file_exists($CFG->libdir . $class . '.php')) {
		throw new Exception('Klasse ' . $class . ' nicht gefunden');
	}
	
	require_once($CFG->libdir . $class . '.php');
});
