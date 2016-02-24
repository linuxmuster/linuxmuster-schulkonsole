#!/usr/bin/php
<?php
/**
 * schulkonsole mail (ingo) external API interface.
 *
 * This file defines functions to read/change forwards for a user.
 *
 *
 * See the enclosed file LICENSE for license information (ASL).  If you
 * did not receive this file, see http://www.horde.org/licenses/asl.php.
 *
 * Copyright 2016, Frank Schütte
 */
 
//ini_set('display_errors',1);
//ini_set('display_startup_errors',1);
//function kill( $data ) { die( var_dump ( $data ) ); }

session_start();

/**
 * horde initialization
 *
 * HORDE_BASE   - must be defined for all horde applications
 * AUTH_HANDLER - this application handles authorization
 * no_compress  - output is not compressed
 */

@define('HORDE_BASE', '/usr/share/horde3');
@define('AUTH_HANDLER', true);
$no_compress = true;

// Do CLI checks and environment setup first.
require_once HORDE_BASE . '/lib/core.php';
require_once 'Horde/CLI.php';

// Make sure no one runs this from the web.
if (!Horde_CLI::runningFromCLI()) {
    session_destroy();
    exit("Must be run from the command line\n");
}

// Load the CLI environment - make sure there's no time limit, init some
// variables, etc.
Horde_CLI::init();
$cli = &Horde_CLI::singleton();

// Include needed libraries.
require_once HORDE_BASE . '/lib/base.php';
require_once 'Horde/Secret.php';

/* Get an Auth object. */
$auth = &Auth::singleton($conf['auth']['driver']);
if (is_a($auth, 'PEAR_Error')) {
   Horde::fatal($auth, __FILE__, __LINE__);
}

// *** command line args handling ***
$shortopts = "u:p:gs:rkh";

$longopts = array (
    "user:",
    "password:",
    "get-forwards",
    "set-forwards:",
    "remove-forwards",
    "keep",
    "help",
);

$options = getopt($shortopts, $longopts);

// *** convert all options to longopts ***
foreach($options as $opt) {
    switch($opt) {
        case "u":
            $options['user'] = $options['u'];
            break;
        case "p":
            $options['password'] = $options['p'];
            break;
        case "g":
            $options['get-forwards'] = $options['g'];
            break;
        case "s":
            $options['set-forwards'] = $options['s'];
            break;
        case "r":
            $options['remove-forwards'] = $options['r'];
            break;
        case "k":
            $options['keep'] = $options['k'];
            break;
        case "h":
            $options['help'] = $options['h'];
            break;
        default:
            break;
    }
}

// *** parse options ***
if(!isset($options['user']) || !isset($options['password'])) {
    $options['help'] = true;
}

if(!isset($options['get-forwards']) && !isset($options['set-forwards']) 
    && !isset($options['remove-forwards'])) {
    $options['help'] = true;
}

if(isset($options['get-forwards']) 
        && (isset($options['set-forwards']) || isset($options['remove-forwards']))
    || isset($options['set-forwards']) && isset($options['remove-forwards'])) {
    $options['help'] = true;
}

if(isset($options['keep']) && !isset($options['set-forwards'])) {
    $options['help'] = true;
}

if(isset($options['help'])) {
echo<<<EOF
horde-mail.php prints or sets forwards by means of there
horde3 api named ingo. In linuxmuster.net settings the horde
prefs db and the sieve filter script is updated.

Parameters:

    -h|--help                display this help text

    identification
    --------------
    -u|--user=string         username to manage forwards for
    -p|--password=string     password of the user
    
    action
    ------
    -g|--get-forwards        read forwards
    -s|--set-forwards=stringlist
                             print forwards to stdout
    -r|--remove-forwards     remove all forwards
    
    option
    ------
    -k|--keep                keep a copy of all forwarded mail

EOF;
session_destroy();
exit;
}
$auth_success = $auth->authenticate($options['user'], array('password' => $options['password']), true);
if (is_a($auth, 'PEAR_Error')) {
	$cli->message(_("Authentication error."), 'cli.error');
	session_destroy();
	exit(1);
}
if(! $auth_success) {
	$cli->message(_("Authentication error."), 'cli.error');
	session_destroy();
	exit(1);
}

@define('INGO_BASE', '/usr/share/horde3/ingo');
require_once INGO_BASE . '/lib/base.php';

/* Redirect if forward is not available. */
if (!in_array(INGO_STORAGE_ACTION_FORWARD, $_SESSION['ingo']['script_categories'])) {
    $cli->message("Forward is not supported in the current filtering driver.", 'cli.error');
    exit(1);
}

if (is_a(($pushed = $registry->pushApp('ingo', !defined('AUTH_HANDLER'))), 'PEAR_Error')) {
    $cli->message('Cannot switch to ingo registry.','cli.error');
    session_destroy();
    exit(1);
}



/// *** main ***

if(isset($options['get-forwards'])) {
    $forwards = getForwards();
    echo $options['user'],";";
    echo implode(",", $forwards['addresses']),";";
    if($forwards['keep']) {
        echo "keep";
    }
    echo "\n";
} else if(isset($options['set-forwards'])) {
    $addresses = explode(",", $options['set-forwards']);
    if(isset($options['keep'])) {
        setForwards($addresses, true);
    } else {
        setForwards($addresses);
    }
} else if(isset($options['remove-forwards'])) {
    setForwards();
}
session_destroy();

exit(0);

/**
* Get Forward addresses
*
* @return array ( 
*          string  addresses    The forward addresses
*          boolean keep         Keep copy
*          boolean enabled      Rule is enabled
*         )
*/
function getForwards()
{
    global $ingo_storage,$cli;
    
    /* Redirect if forward is not available. */
    if (!in_array(INGO_STORAGE_ACTION_FORWARD, $_SESSION['ingo']['script_categories'])) {
        $cli->message(_("Forward is not supported in the current filtering driver."), 'cli.error');
	session_destroy();
        exit;
    }
    /* Get the forward object and rule. */
    $forward = &$ingo_storage->retrieve(INGO_STORAGE_ACTION_FORWARD);
    $filters = &$ingo_storage->retrieve(INGO_STORAGE_ACTION_FILTERS);
    $fwd_id = $filters->findRuleId(INGO_STORAGE_ACTION_FORWARD);
    $fwd_rule = $filters->getRule($fwd_id);
    $params = array();
    if(isset($fwd_rule['disable'])) {
      $params['enabled'] = ! $fwd_rule['disable'];
    } else {
      $params['enabled'] = true;
    }
    $params['keep'] = $forward->getForwardKeep();
    $params['addresses'] = $forward->getForwardAddresses();
    return $params;
}

/**
* Set Forward addresses
*
* @param string $addresses    The addresses to set
* @param boolean $keep        Keep copy
*/
function setForwards($addresses = array(),$keep = false)
{
    /* Redirect if forward is not available. */
    if (!in_array(INGO_STORAGE_ACTION_FORWARD, $_SESSION['ingo']['script_categories'])) {
        $cli->message(_("Forward is not supported in the current filtering driver."), 'cli.error');
	session_destroy();
        exit;
    }

    global $ingo_storage,$cli;
    /* Get the forward object and rule. */
    $forward = &$ingo_storage->retrieve(INGO_STORAGE_ACTION_FORWARD);
    $filters = &$ingo_storage->retrieve(INGO_STORAGE_ACTION_FILTERS);
    $fwd_id = $filters->findRuleId(INGO_STORAGE_ACTION_FORWARD);
    $fwd_rule = $filters->getRule($fwd_id);

    $forward->setForwardAddresses($addresses);
    $forward->setForwardKeep($keep);
    $success = true;

    if (is_a($result = $ingo_storage->store($forward), 'PEAR_Error')) {
        $cli->message($result,'cli.error');
        $success = false;
    } else {
        $cli->message(_("Changes saved."), 'cli.success');
        if (!empty($addresses)) {
            $filters->ruleEnable($fwd_id);
            if (is_a($result = $ingo_storage->store($filters), 'PEAR_Error')) {
                $cli->message($result,'cli.error');
                $success = false;
            } else {
                $cli->message(_("Rule Enabled"), 'cli.success');
                $fwd_rule['disable'] = false;
            }
        } else {
            $filters->ruleDisable($fwd_id);
            if (is_a($result = $ingo_storage->store($filters), 'PEAR_Error')) {
                $cli->message($result,'cli.error');
                $success = false;
            } else {
                $cli->message(_("Rule Disabled"), 'cli.success');
                $fwd_rule['disable'] = true;
            }
        }
    }
    if ($success) {
        Ingo::updateScript();
    }
}
