<?php
class Wrapper {
        protected $wrapperFile;
	protected $appID;
	protected $id;
	protected $password;
	public $out;
	public $in;
	public $err;
        public $process;
        
        /**
         * Erstellt eine neue Wrapperinstanz.
         *
         * @param	string		$wrapperFile	Ausführbare Wrapperfa
         * @param	integer		$appID
         * @param	integer		$id		Benutzer ID.
         * @param	string		$password	Benutzerkennwort.
         */
        public function __construct($wrapperFile, $appID, $id, $password) {
            $this->wrapperFile = $wrapperFile;
            $this->appID = $appID;
            $this->id = $id;
            $this->password = $password;
        }
        
        public function __destruct() {
            $this->stop();
        }
        
	public function start() {
            $wrapperDir = '/usr/lib/schulkonsole/bin/';
            
            $descriptorspec = array(
                0 => array('pipe', 'r'),
                1 => array('pipe', 'w'),
                2 => array('pipe', 'w')
            );
            $pipes = array();
            
            $this->process = proc_open($wrapperDir . $this->wrapperFile, $descriptorspec, $pipes, $wrapperDir);
            
            if(!is_resource($this->process)) {
                throw new Exception('Wrapperaufruf fehlgeschlagen: ' . $wrapperDir . $this->wrapperFile . '!');
            }
            
            list($this->in, $this->out, $this->err) = $pipes;
            
            $this->write($this->id . "\n" . $this->password . "\n" . $this->appID . "\n");
	}
        
        public function stop() {
            if(is_resource($this->process)) {
                fclose($this->in);
                fclose($this->out);
                fclose($this->err);
                $state = proc_close($this->process);
            }
        }
        
        public function write($string) {
            fwrite($this->in, $string);
        }
        
        public function read() {
            return stream_get_contents($this->out);
        }
        
}
