<?php
class File {
    const BACKUP_CONF_FILE = 1;
    const BACKUP_CONF_NAME = '/etc/linuxmuster/backup.conf';
    const WRAPPER_BACKUP = 'wrapper-backup';
    
    private static $bools = array('firewall','verify','unmount','cronbackup');
    
    public static function isBool($var) {
        if(in_array($var, File::$bools))
            return true;
        else
            return false;
    }
    
    public static function toBool($var) {
        if (!is_string($var)) { 
            return (bool) $var;
        }
        switch (strtolower($var)) {
          case '1':
          case 'true':
          case 'on':
          case 'yes':
          case 'y':
            return true;
          default:
            return false;
        }
    }
    
    public static function read_backup_conf() {
        $bc = parse_ini_file(File::BACKUP_CONF_NAME);
        foreach($bc as $key => $value) {
            if(File::isBool($key)) {
                $bc[$key] = File::toBool($value);
            }
        }
        return $bc;
    }
    
    public static function read_backup_conf_lines() {
        return file(File::BACKUP_CONF_NAME,FILE_IGNORE_NEW_LINES);
    }
    
    public static function write($fileID, array $lines, Session $session) {
        $wrapper = new Wrapper(File::WRAPPER_BACKUP, '91001', $session->id, $session->password);
        $wrapper->start();
        
        $wrapper->write($fileID . "\n" . implode("\n", $lines));
        
        $wrapper->stop();
    }

    public static function new_backup_lines($values_new) {
	$lines = array();
	if ($bclines = File::read_backup_conf_lines()) {
            foreach($bclines as $line) {
                if( preg_match('/^\s*([\w]+)\s*=/', $line, $matches) ) {
                    $key = $matches[1];
                    if(!isset($values_new[$key])) {
                        continue;
                    }
                    if (File::isBool($key)) {
                            $value = (File::toBool($values_new[$key]) ? "yes" : "no");
                    } else {
                            $value = $values_new[$key];
                    }
                    $line = "$key=$value";
                    unset( $values_new[$key] );
                }
                array_push($lines, $line);
            }
	}

	if (isset($values_new) && count($values_new) > 0) {
            array_push($lines, "# schulkonsole");
            foreach($values_new as $key => $value) {
                if (isBool($key)) {
                    $value = (toBool($value) ? "yes" : "no");
                }
                array_push($lines, "$key=$value");
            }
	}
	return $lines;
    }
}